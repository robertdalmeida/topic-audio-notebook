import Foundation

protocol StorageProvider {
    func saveTopics(_ topics: [Topic]) async throws
    func loadTopics() async throws -> [Topic]
    func saveAudioFile(data: Data, filename: String) async throws -> URL
    func deleteAudioFile(at url: URL) async throws
    func clearAllData() async throws
}

enum StorageType: String, CaseIterable, Codable {
    case file = "File Storage"
    case coreData = "Core Data"
    
    var description: String {
        switch self {
        case .file:
            return "Stores data as JSON and audio files in the Documents directory"
        case .coreData:
            return "Stores data in a local Core Data database"
        }
    }
}

enum StorageError: LocalizedError {
    case encodingFailed
    case decodingFailed
    case fileNotFound
    case saveFailed(String)
    case loadFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .fileNotFound:
            return "File not found"
        case .saveFailed(let message):
            return "Save failed: \(message)"
        case .loadFailed(let message):
            return "Load failed: \(message)"
        case .deleteFailed(let message):
            return "Delete failed: \(message)"
        }
    }
}
