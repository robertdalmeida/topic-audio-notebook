import Foundation
import Combine

@MainActor
final class TopicRepository: ObservableObject, TopicRepositoryProtocol {
    @Published private(set) var topics: [Topic] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var currentStorageType: StorageType = .file
    
    var topicsPublisher: AnyPublisher<[Topic], Never> {
        $topics.eraseToAnyPublisher()
    }
    
    private let fileManager = FileManager.default
    private let storageManager = StorageManager.shared
    private let summarizationService: StateManagedSummarizationService
    
    init(stateManager: SummarizationStateManager = .shared) {
        self.summarizationService = StateManagedSummarizationService(stateManager: stateManager)
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
        topics[index].consolidatedSummary = nil
        topics[index].consolidatedPoints = nil
        saveTopics()
        
        Task {
            await transcribeRecording(recordingId: recording.id, in: topicId)
        }
    }
    
    func deleteRecording(_ recording: Recording, from topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        topics[topicIndex].recordings.removeAll { $0.id == recording.id }
        topics[topicIndex].updatedAt = Date()
        topics[topicIndex].consolidatedSummary = nil
        topics[topicIndex].consolidatedPoints = nil
        
        try? fileManager.removeItem(at: recording.fileURL)
        saveTopics()
        
        if topics[topicIndex].hasContentForSummary {
            Task {
                await consolidateSummary(for: topicId)
            }
        }
    }
    
    // MARK: - Note Management
    
    func addNote(to topicId: UUID, content: String) {
        guard let index = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        let note = Note(content: content)
        topics[index].notes.append(note)
        topics[index].updatedAt = Date()
        topics[index].consolidatedSummary = nil
        topics[index].consolidatedPoints = nil
        saveTopics()
        
        Task {
            await consolidateSummary(for: topicId)
        }
    }
    
    func updateNote(_ note: Note, in topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let noteIndex = topics[topicIndex].notes.firstIndex(where: { $0.id == note.id }) else {
            return
        }
        
        var updatedNote = note
        updatedNote.updatedAt = Date()
        topics[topicIndex].notes[noteIndex] = updatedNote
        topics[topicIndex].updatedAt = Date()
        topics[topicIndex].consolidatedSummary = nil
        topics[topicIndex].consolidatedPoints = nil
        saveTopics()
        
        Task {
            await consolidateSummary(for: topicId)
        }
    }
    
    func deleteNote(_ note: Note, from topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }) else { return }
        
        topics[topicIndex].notes.removeAll { $0.id == note.id }
        topics[topicIndex].updatedAt = Date()
        topics[topicIndex].consolidatedSummary = nil
        topics[topicIndex].consolidatedPoints = nil
        saveTopics()
        
        if topics[topicIndex].hasContentForSummary {
            Task {
                await consolidateSummary(for: topicId)
            }
        }
    }
    
    // MARK: - Archive/Unarchive
    
    func archiveRecording(_ recording: Recording, in topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let recordingIndex = topics[topicIndex].recordings.firstIndex(where: { $0.id == recording.id }) else {
            return
        }
        topics[topicIndex].recordings[recordingIndex].isArchived = true
        topics[topicIndex].updatedAt = Date()
        saveTopics()
        
        Task {
            await consolidateSummary(for: topicId)
        }
    }
    
    func unarchiveRecording(_ recording: Recording, in topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let recordingIndex = topics[topicIndex].recordings.firstIndex(where: { $0.id == recording.id }) else {
            return
        }
        topics[topicIndex].recordings[recordingIndex].isArchived = false
        topics[topicIndex].updatedAt = Date()
        saveTopics()
        
        Task {
            await consolidateSummary(for: topicId)
        }
    }
    
    func archiveNote(_ note: Note, in topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let noteIndex = topics[topicIndex].notes.firstIndex(where: { $0.id == note.id }) else {
            return
        }
        topics[topicIndex].notes[noteIndex].isArchived = true
        topics[topicIndex].updatedAt = Date()
        saveTopics()
        
        Task {
            await consolidateSummary(for: topicId)
        }
    }
    
    func unarchiveNote(_ note: Note, in topicId: UUID) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let noteIndex = topics[topicIndex].notes.firstIndex(where: { $0.id == note.id }) else {
            return
        }
        topics[topicIndex].notes[noteIndex].isArchived = false
        topics[topicIndex].updatedAt = Date()
        saveTopics()
        
        Task {
            await consolidateSummary(for: topicId)
        }
    }
    
    // MARK: - Transcription
    
    func updateRecordingTranscript(recordingId: UUID, in topicId: UUID, transcript: String) {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let recordingIndex = topics[topicIndex].recordings.firstIndex(where: { $0.id == recordingId }) else {
            return
        }
        
        topics[topicIndex].recordings[recordingIndex].transcript = transcript
        topics[topicIndex].recordings[recordingIndex].transcriptionStatus = .completed
        topics[topicIndex].updatedAt = Date()
        saveTopics()
        
        Task {
            await consolidateSummary(for: topicId)
        }
    }
    
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
            
            await consolidateSummary(for: topicId)
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
    
    func generateRecordingKeyPoints(recordingId: UUID, in topicId: UUID) async {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let recordingIndex = topics[topicIndex].recordings.firstIndex(where: { $0.id == recordingId }),
              let transcript = topics[topicIndex].recordings[recordingIndex].transcript else {
            return
        }
        
        do {
            let points = try await summarizationService.generateKeyPoints([transcript])
            topics[topicIndex].recordings[recordingIndex].summaryPoints = points
            topics[topicIndex].updatedAt = Date()
            saveTopics()
        } catch {
            errorMessage = "Key points generation failed: \(error.localizedDescription)"
        }
    }
    
    func generateRecordingFullSummary(recordingId: UUID, in topicId: UUID) async {
        guard let topicIndex = topics.firstIndex(where: { $0.id == topicId }),
              let recordingIndex = topics[topicIndex].recordings.firstIndex(where: { $0.id == recordingId }),
              let transcript = topics[topicIndex].recordings[recordingIndex].transcript else {
            return
        }
        
        do {
            let summary = try await summarizationService.generateFullSummary([transcript])
            topics[topicIndex].recordings[recordingIndex].summary = summary
            topics[topicIndex].recordings[recordingIndex].summaryStatus = .completed
            topics[topicIndex].updatedAt = Date()
            saveTopics()
        } catch {
            if case SummarizationError.noAPIKey = error {
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
        
        let allContent = topics[topicIndex].allContent
        guard !allContent.isEmpty else {
            errorMessage = "No content available to consolidate"
            return
        }
        
        isLoading = true
        
        do {
            async let keyPoints = summarizationService.generateKeyPoints(allContent)
            async let fullSummary = summarizationService.generateFullSummary(allContent)
            
            let (points, summary) = try await (keyPoints, fullSummary)
            
            topics[topicIndex].consolidatedSummary = summary
            topics[topicIndex].consolidatedPoints = points
            topics[topicIndex].updatedAt = Date()
            saveTopics()
        } catch {
            errorMessage = "Consolidation failed: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Persistence
    
    private func saveTopics() {
        Task {
            do {
                try await storageManager.saveTopics(topics)
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
            }
        }
    }
    
    private func loadTopics() async {
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
    
    func topic(for id: UUID) -> Topic? {
        topics.first { $0.id == id }
    }
    
    func recording(id: UUID, in topicId: UUID) -> Recording? {
        topic(for: topicId)?.recordings.first { $0.id == id }
    }
}