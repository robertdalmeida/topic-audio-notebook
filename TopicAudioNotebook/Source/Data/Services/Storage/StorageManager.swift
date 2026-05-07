import Foundation

@MainActor
class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published private(set) var currentStorageType: StorageType
    
    private var fileStorage: FileStorageProvider
    private var coreDataStorage: CoreDataStorageProvider
    
    private let storageTypeKey = "SelectedStorageType"
    
    var currentProvider: StorageProvider {
        switch currentStorageType {
        case .file:
            return fileStorage
        case .coreData:
            return coreDataStorage
        }
    }
    
    private init() {
        let savedType = UserDefaults.standard.string(forKey: storageTypeKey)
        self.currentStorageType = StorageType(rawValue: savedType ?? "") ?? .file
        self.fileStorage = FileStorageProvider()
        self.coreDataStorage = CoreDataStorageProvider()
    }
    
    func switchStorage(to type: StorageType, migrateData: Bool = true, topics: [Topic]) async throws {
        guard type != currentStorageType else { return }
        
        log.info("[StorageManager] Switching storage from \(currentStorageType) to \(type)", category: .general)
        
        if migrateData {
            log.info("[StorageManager] Migrating data to new storage provider", category: .general)
            let newProvider: StorageProvider = type == .file ? fileStorage : coreDataStorage
            try await newProvider.saveTopics(topics)
        }
        
        currentStorageType = type
        UserDefaults.standard.set(type.rawValue, forKey: storageTypeKey)
    }
    
    func saveTopics(_ topics: [Topic]) async throws {
        do {
            try await currentProvider.saveTopics(topics)
        } catch {
            log.error("[StorageManager] Failed to save topics: \(error.localizedDescription)", category: .general)
            throw error
        }
    }
    
    func loadTopics() async throws -> [Topic] {
        log.info("[StorageManager] Loading topics from \(currentStorageType)", category: .general)
        do {
            return try await currentProvider.loadTopics()
        } catch {
            log.error("[StorageManager] Failed to load topics: \(error.localizedDescription)", category: .general)
            throw error
        }
    }
    
    func saveAudioFile(data: Data, filename: String) async throws -> URL {
        try await currentProvider.saveAudioFile(data: data, filename: filename)
    }
    
    func deleteAudioFile(at url: URL) async throws {
        try await currentProvider.deleteAudioFile(at: url)
    }
    
    func clearAllData() async throws {
        try await currentProvider.clearAllData()
    }
}
