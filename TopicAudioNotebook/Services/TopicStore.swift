import Foundation
import Combine

@MainActor
class TopicStore: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentStorageType: StorageType = .file
    
    private let fileManager = FileManager.default
    private let storageManager = StorageManager.shared
    
    init() {
        currentStorageType = storageManager.currentStorageType
        Task {
            await loadTopics()
        }
    }
    
    // MARK: - Topic Management
    
    func addTopic(name: String, description: String = "", color: TopicColor = .blue) {
        let topic = Topic(name: name, description: description, color: color)
        topics.append(topic)
        saveTopics()
    }
    
    func updateTopic(_ topic: Topic) {
        if let index = topics.firstIndex(where: { $0.id == topic.id }) {
            var updatedTopic = topic
            updatedTopic.updatedAt = Date()
            topics[index] = updatedTopic
            saveTopics()
        }
    }
    
    func deleteTopic(_ topic: Topic) {
        topics.removeAll { $0.id == topic.id }
        deleteTopicRecordings(topic)
        saveTopics()
    }
    
    // MARK: - Recording Management
    
    func addRecording(to topicId: UUID, title: String, fileURL: URL, duration: TimeInterval) {
        guard let index = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        let recording = Recording(title: title, fileURL: fileURL, duration: duration)
        topics[index].recordings.append(recording)
        topics[index].updatedAt = Date()
        saveTopics()
        
        Task {
            await transcribeRecording(recordingId: recording.id, in: topicId)
        }
    }
    
    func deleteRecording(_ recording: Recording, from topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        topics[topicIndex].recordings.removeAll { $0.id == recording.id }
        topics[topicIndex].updatedAt = Date()
        
        try? fileManager.removeItem(at: recording.fileURL)
        saveTopics()
    }
    
    // MARK: - Transcription
    
    func transcribeRecording(recordingId: UUID, in topicId: UUID) async {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let recordingIndex = topics[topicIndex].recordings.firstIndex(where: { $0.id == recordingId }) else {
            return
        }
        
        topics[topicIndex].recordings[recordingIndex].transcriptionStatus = .inProgress
        
        do {
            let transcript = try await TranscriptionService.shared.transcribe(
                audioURL: topics[topicIndex].recordings[recordingIndex].fileURL
            )
            
            topics[topicIndex].recordings[recordingIndex].transcript = transcript
            topics[topicIndex].recordings[recordingIndex].transcriptionStatus = .completed
            topics[topicIndex].updatedAt = Date()
            saveTopics()
        } catch {
            topics[topicIndex].recordings[recordingIndex].transcriptionStatus = .failed
            errorMessage = "Transcription failed: \(error.localizedDescription)"
            saveTopics()
        }
    }
    
    func retryTranscription(for recording: Recording, in topicId: UUID) {
        Task {
            await transcribeRecording(recordingId: recording.id, in: topicId)
        }
    }
    
    // MARK: - Recording Summary
    
    func generateRecordingSummary(recordingId: UUID, in topicId: UUID) async {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let recordingIndex = topics[topicIndex].recordings.firstIndex(where: { $0.id == recordingId }),
              let transcript = topics[topicIndex].recordings[recordingIndex].transcript else {
            return
        }
        
        topics[topicIndex].recordings[recordingIndex].summaryStatus = .inProgress
        saveTopics()
        
        do {
            let result = try await AIService.shared.summarizeRecording(transcript)
            topics[topicIndex].recordings[recordingIndex].summary = result.summary
            topics[topicIndex].recordings[recordingIndex].summaryPoints = result.points
            topics[topicIndex].recordings[recordingIndex].summaryStatus = .completed
            topics[topicIndex].updatedAt = Date()
            saveTopics()
        } catch {
            if case AIServiceError.noAPIKey = error {
                topics[topicIndex].recordings[recordingIndex].summaryStatus = .notAvailable
            } else {
                topics[topicIndex].recordings[recordingIndex].summaryStatus = .failed
            }
            errorMessage = "Summary generation failed: \(error.localizedDescription)"
            saveTopics()
        }
    }
    
    // MARK: - Consolidation
    
    func consolidateSummary(for topicId: UUID) async {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        let transcripts = topics[topicIndex].allTranscripts
        guard !transcripts.isEmpty else {
            errorMessage = "No transcripts available to consolidate"
            return
        }
        
        isLoading = true
        
        do {
            let result = try await AIService.shared.consolidateTranscriptsWithPoints(transcripts)
            topics[topicIndex].consolidatedSummary = result.summary
            topics[topicIndex].consolidatedPoints = result.points
            topics[topicIndex].updatedAt = Date()
            saveTopics()
        } catch {
            errorMessage = "Consolidation failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Persistence
    
    func saveTopics() {
        Task {
            do {
                try await storageManager.saveTopics(topics)
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
    
    func loadTopics() async {
        do {
            topics = try await storageManager.loadTopics()
        } catch {
            errorMessage = "Failed to load: \(error.localizedDescription)"
        }
    }
    
    private func deleteTopicRecordings(_ topic: Topic) {
        Task {
            for recording in topic.recordings {
                try? await storageManager.deleteAudioFile(at: recording.fileURL)
            }
        }
    }
    
    // MARK: - Storage Management
    
    func switchStorage(to type: StorageType) async {
        do {
            try await storageManager.switchStorage(to: type, migrateData: true, topics: topics)
            currentStorageType = type
        } catch {
            errorMessage = "Failed to switch storage: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Helpers
    
    func getRecordingsDirectory() -> URL {
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let recordingsDir = paths[0].appendingPathComponent("Recordings", isDirectory: true)
        
        if !fileManager.fileExists(atPath: recordingsDir.path) {
            try? fileManager.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        }
        
        return recordingsDir
    }
}
