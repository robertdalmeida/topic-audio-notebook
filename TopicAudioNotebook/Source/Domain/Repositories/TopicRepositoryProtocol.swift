import Foundation
import Combine

protocol TopicRepositoryProtocol: AnyObject {
    var topics: [Topic] { get }
    var topicsPublisher: AnyPublisher<[Topic], Never> { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }
    
    func addTopic(name: String, description: String, color: TopicColor)
    func updateTopic(_ topic: Topic)
    func deleteTopic(_ topic: Topic)
    
    func addRecording(to topicId: UUID, title: String, fileURL: URL, duration: TimeInterval)
    func deleteRecording(_ recording: Recording, from topicId: UUID)
    
    func addNote(to topicId: UUID, content: String)
    func updateNote(_ note: Note, in topicId: UUID)
    func deleteNote(_ note: Note, from topicId: UUID)
    
    func archiveRecording(_ recording: Recording, in topicId: UUID)
    func unarchiveRecording(_ recording: Recording, in topicId: UUID)
    func archiveNote(_ note: Note, in topicId: UUID)
    func unarchiveNote(_ note: Note, in topicId: UUID)
    
    func updateRecordingTranscript(recordingId: UUID, in topicId: UUID, transcript: String)
    func transcribeRecording(recordingId: UUID, in topicId: UUID) async
    func retryTranscription(for recording: Recording, in topicId: UUID)
    
    func generateRecordingKeyPoints(recordingId: UUID, in topicId: UUID) async
    func generateRecordingFullSummary(recordingId: UUID, in topicId: UUID) async
    func consolidateSummary(for topicId: UUID) async
    
    func getRecordingsDirectory() -> URL
    func switchStorage(to type: StorageType) async
    var currentStorageType: StorageType { get }
}
