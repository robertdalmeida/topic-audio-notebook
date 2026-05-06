import Foundation
import Combine

@MainActor
final class RecordingDetailViewModel: ObservableObject {
    @Published private(set) var recording: Recording
    @Published var selectedTab = 0
    @Published private(set) var isGeneratingSummary = false
    
    private let recordingId: UUID
    private let topicId: UUID
    private let repository: TopicRepository
    let audioPlayer: AudioPlayer
    
    var hasTranscript: Bool {
        recording.transcript != nil
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
    
    func generateSummary() {
        isGeneratingSummary = true
        Task {
            await repository.generateRecordingSummary(recordingId: recordingId, in: topicId)
            isGeneratingSummary = false
        }
    }
}
