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
        
        if migrateData {
            let newProvider: StorageProvider = type == .file ? fileStorage : coreDataStorage
            try await newProvider.saveTopics(topics)
        }
        
        currentStorageType = type
        UserDefaults.standard.set(type.rawValue, forKey: storageTypeKey)
    }
    
    func saveTopics(_ topics: [Topic]) async throws {
        try await currentProvider.saveTopics(topics)
    }
    
    func loadTopics() async throws -> [Topic] {
        try await currentProvider.loadTopics()
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
