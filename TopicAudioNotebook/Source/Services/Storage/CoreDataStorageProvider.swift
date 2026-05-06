import Foundation
import CoreData

actor CoreDataStorageProvider: StorageProvider {
    private let container: NSPersistentContainer
    private let fileManager = FileManager.default
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var recordingsDirectory: URL {
        documentsDirectory.appendingPathComponent("Recordings", isDirectory: true)
    }
    
    init() {
        container = NSPersistentContainer(name: "TopicAudioNotebook")
        
        let description = NSPersistentStoreDescription()
        description.type = NSSQLiteStoreType
        description.url = documentsDirectory.appendingPathComponent("TopicAudioNotebook.sqlite")
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - StorageProvider
    
    func saveTopics(_ topics: [Topic]) async throws {
        let context = container.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TopicEntity")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try? context.execute(deleteRequest)
            
            for topic in topics {
                let topicEntity = NSEntityDescription.insertNewObject(forEntityName: "TopicEntity", into: context)
                topicEntity.setValue(topic.id, forKey: "id")
                topicEntity.setValue(topic.name, forKey: "name")
                topicEntity.setValue(topic.description, forKey: "topicDescription")
                topicEntity.setValue(topic.color.rawValue, forKey: "color")
                topicEntity.setValue(topic.createdAt, forKey: "createdAt")
                topicEntity.setValue(topic.updatedAt, forKey: "updatedAt")
                topicEntity.setValue(topic.consolidatedSummary, forKey: "consolidatedSummary")
                
                if let points = topic.consolidatedPoints {
                    topicEntity.setValue(try? JSONEncoder().encode(points), forKey: "consolidatedPointsData")
                }
                
                for recording in topic.recordings {
                    let recordingEntity = NSEntityDescription.insertNewObject(forEntityName: "RecordingEntity", into: context)
                    recordingEntity.setValue(recording.id, forKey: "id")
                    recordingEntity.setValue(recording.title, forKey: "title")
                    recordingEntity.setValue(recording.fileURL.absoluteString, forKey: "fileURLString")
                    recordingEntity.setValue(recording.duration, forKey: "duration")
                    recordingEntity.setValue(recording.transcript, forKey: "transcript")
                    recordingEntity.setValue(recording.summary, forKey: "summary")
                    recordingEntity.setValue(recording.transcriptionStatus.rawValue, forKey: "transcriptionStatus")
                    recordingEntity.setValue(recording.summaryStatus.rawValue, forKey: "summaryStatus")
                    recordingEntity.setValue(recording.createdAt, forKey: "createdAt")
                    recordingEntity.setValue(topicEntity, forKey: "topic")
                    
                    if let points = recording.summaryPoints {
                        recordingEntity.setValue(try? JSONEncoder().encode(points), forKey: "summaryPointsData")
                    }
                }
            }
            
            try context.save()
        }
    }
    
    func loadTopics() async throws -> [Topic] {
        let context = container.newBackgroundContext()
        
        return try await context.perform {
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "TopicEntity")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let topicEntities = try context.fetch(fetchRequest)
            
            return topicEntities.compactMap { entity -> Topic? in
                guard let id = entity.value(forKey: "id") as? UUID,
                      let name = entity.value(forKey: "name") as? String else {
                    return nil
                }
                
                let description = entity.value(forKey: "topicDescription") as? String ?? ""
                let colorRaw = entity.value(forKey: "color") as? String ?? "blue"
                let color = TopicColor(rawValue: colorRaw) ?? .blue
                let createdAt = entity.value(forKey: "createdAt") as? Date ?? Date()
                let updatedAt = entity.value(forKey: "updatedAt") as? Date ?? Date()
                let consolidatedSummary = entity.value(forKey: "consolidatedSummary") as? String
                
                var consolidatedPoints: [String]?
                if let pointsData = entity.value(forKey: "consolidatedPointsData") as? Data {
                    consolidatedPoints = try? JSONDecoder().decode([String].self, from: pointsData)
                }
                
                let recordingEntities = entity.value(forKey: "recordings") as? Set<NSManagedObject> ?? []
                let recordings = recordingEntities.compactMap { recEntity -> Recording? in
                    guard let recId = recEntity.value(forKey: "id") as? UUID,
                          let title = recEntity.value(forKey: "title") as? String,
                          let fileURLString = recEntity.value(forKey: "fileURLString") as? String,
                          let fileURL = URL(string: fileURLString) else {
                        return nil
                    }
                    
                    let duration = recEntity.value(forKey: "duration") as? TimeInterval ?? 0
                    let transcript = recEntity.value(forKey: "transcript") as? String
                    let summary = recEntity.value(forKey: "summary") as? String
                    let transcriptionStatusRaw = recEntity.value(forKey: "transcriptionStatus") as? String ?? "Pending"
                    let summaryStatusRaw = recEntity.value(forKey: "summaryStatus") as? String ?? "Pending"
                    let recCreatedAt = recEntity.value(forKey: "createdAt") as? Date ?? Date()
                    
                    var summaryPoints: [String]?
                    if let pointsData = recEntity.value(forKey: "summaryPointsData") as? Data {
                        summaryPoints = try? JSONDecoder().decode([String].self, from: pointsData)
                    }
                    
                    let transcriptionStatus = TranscriptionStatus(rawValue: transcriptionStatusRaw) ?? .pending
                    let summaryStatus = SummaryStatus(rawValue: summaryStatusRaw) ?? .pending
                    
                    return Recording(
                        id: recId,
                        title: title,
                        fileURL: fileURL,
                        duration: duration,
                        transcript: transcript,
                        summary: summary,
                        summaryPoints: summaryPoints,
                        transcriptionStatus: transcriptionStatus,
                        summaryStatus: summaryStatus,
                        createdAt: recCreatedAt
                    )
                }.sorted { $0.createdAt < $1.createdAt }
                
                return Topic(
                    id: id,
                    name: name,
                    description: description,
                    recordings: recordings,
                    consolidatedSummary: consolidatedSummary,
                    consolidatedPoints: consolidatedPoints,
                    createdAt: createdAt,
                    updatedAt: updatedAt,
                    color: color
                )
            }
        }
    }
    
    func saveAudioFile(data: Data, filename: String) async throws -> URL {
        let fileURL = recordingsDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL, options: .atomic)
            return fileURL
        } catch {
            throw StorageError.saveFailed(error.localizedDescription)
        }
    }
    
    func deleteAudioFile(at url: URL) async throws {
        guard fileManager.fileExists(atPath: url.path) else {
            return
        }
        
        do {
            try fileManager.removeItem(at: url)
        } catch {
            throw StorageError.deleteFailed(error.localizedDescription)
        }
    }
    
    func clearAllData() async throws {
        let context = container.newBackgroundContext()
        
        try await context.perform {
            let topicFetch: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "TopicEntity")
            let topicDelete = NSBatchDeleteRequest(fetchRequest: topicFetch)
            try? context.execute(topicDelete)
            
            let recordingFetch: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "RecordingEntity")
            let recordingDelete = NSBatchDeleteRequest(fetchRequest: recordingFetch)
            try? context.execute(recordingDelete)
            
            try context.save()
        }
        
        if fileManager.fileExists(atPath: recordingsDirectory.path) {
            try? fileManager.removeItem(at: recordingsDirectory)
            try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        }
    }
}
