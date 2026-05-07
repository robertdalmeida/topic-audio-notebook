import Foundation
import Combine

@MainActor
final class RecordingRowViewModel: ObservableObject {
    @Published private(set) var recording: Recording
    
    private let recordingId: UUID
    private let topicId: UUID
    private let repository: TopicRepository
    
    var hasTranscript: Bool {
        guard let transcript = recording.transcript else { return false }
        return !transcript.isEmpty
    }
    
    init(recordingId: UUID, topicId: UUID, repository: TopicRepository) {
        self.recordingId = recordingId
        self.topicId = topicId
        self.repository = repository
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
    
    // MARK: - Actions
    
    func retryTranscription() {
        if recording.transcriptionStatus == .failed {
            repository.retryTranscription(for: recording, in: topicId)
        }
    }
}
