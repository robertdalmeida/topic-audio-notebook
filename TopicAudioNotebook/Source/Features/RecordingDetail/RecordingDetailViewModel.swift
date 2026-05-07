import Foundation
import Combine

enum RecordingTab: Int, CaseIterable {
    case transcript = 0
    case keyPoints = 1
    case summary = 2
    
    var title: String {
        switch self {
        case .transcript: return "Transcript"
        case .keyPoints: return "Key Points"
        case .summary: return "Summary"
        }
    }
}

@MainActor
final class RecordingDetailViewModel: ObservableObject {
    @Published private(set) var recording: Recording
    @Published var selectedTab: RecordingTab = .transcript
    @Published private(set) var isGeneratingKeyPoints = false
    @Published private(set) var isGeneratingSummary = false
    @Published private(set) var isTranscribing = false
    
    private let recordingId: UUID
    private let topicId: UUID
    private let repository: TopicRepository
    let audioPlayer: AudioPlayer
    
    var hasTranscript: Bool {
        recording.transcript != nil
    }
    
    var hasKeyPoints: Bool {
        recording.summaryPoints != nil && !recording.summaryPoints!.isEmpty
    }
    
    var hasSummary: Bool {
        recording.summary != nil && !recording.summary!.isEmpty
    }
    
    init(
        recordingId: UUID,
        topicId: UUID,
        repository: TopicRepository,
        audioPlayer: AudioPlayer? = nil
    ) {
        self.recordingId = recordingId
        self.topicId = topicId
        self.repository = repository
        self.audioPlayer = audioPlayer ?? AudioPlayer()
        self.recording = repository.recording(id: recordingId, in: topicId) ?? Recording(
            title: "Unknown",
            fileURL: URL(fileURLWithPath: "/")
        )
        setupBindings()
    }
    
    private func setupBindings() {
        repository.$topics
            .compactMap { [recordingId, topicId] topics in
                topics.first { $0.id == topicId }?
                    .recordings.first { $0.id == recordingId }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$recording)
    }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        audioPlayer.load(url: recording.fileURL)
    }
    
    func onDisappear() {
        audioPlayer.stop()
    }
    
    // MARK: - Actions
    
    func generateKeyPoints() {
        isGeneratingKeyPoints = true
        Task {
            await repository.generateRecordingKeyPoints(recordingId: recordingId, in: topicId)
            isGeneratingKeyPoints = false
        }
    }
    
    func generateSummary() {
        isGeneratingSummary = true
        Task {
            await repository.generateRecordingFullSummary(recordingId: recordingId, in: topicId)
            isGeneratingSummary = false
        }
    }
    
    func retranscribe() {
        isTranscribing = true
        Task {
            await repository.transcribeRecording(recordingId: recordingId, in: topicId)
            isTranscribing = false
        }
    }
}
