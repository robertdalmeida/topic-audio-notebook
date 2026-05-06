import Foundation

actor FileStorageProvider: StorageProvider {
    private let fileManager = FileManager.default
    private let topicsFileName = "topics.json"
    private let recordingsDirectoryName = "Recordings"
    private let transcriptsDirectoryName = "Transcripts"
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var topicsFileURL: URL {
        documentsDirectory.appendingPathComponent(topicsFileName)
    }
    
    private var recordingsDirectory: URL {
        documentsDirectory.appendingPathComponent(recordingsDirectoryName, isDirectory: true)
    }
    
    private var transcriptsDirectory: URL {
        documentsDirectory.appendingPathComponent(transcriptsDirectoryName, isDirectory: true)
    }
    
    init() {
        createDirectoriesIfNeeded()
    }
    
    private func createDirectoriesIfNeeded() {
        try? fileManager.createDirectory(at: recordingsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: transcriptsDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - StorageProvider
    
    func saveTopics(_ topics: [Topic]) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(topics)
            try data.write(to: topicsFileURL, options: .atomic)
            
            for topic in topics {
                try await saveTranscripts(for: topic)
            }
        } catch {
            throw StorageError.saveFailed(error.localizedDescription)
        }
    }
    
    func loadTopics() async throws -> [Topic] {
        guard fileManager.fileExists(atPath: topicsFileURL.path) else {
            return []
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let data = try Data(contentsOf: topicsFileURL)
            var topics = try decoder.decode([Topic].self, from: data)
            
            for i in topics.indices {
                topics[i] = try await loadTranscripts(for: topics[i])
            }
            
            return topics
        } catch {
            throw StorageError.loadFailed(error.localizedDescription)
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
        do {
            if fileManager.fileExists(atPath: topicsFileURL.path) {
                try fileManager.removeItem(at: topicsFileURL)
            }
            
            if fileManager.fileExists(atPath: recordingsDirectory.path) {
                try fileManager.removeItem(at: recordingsDirectory)
            }
            
            if fileManager.fileExists(atPath: transcriptsDirectory.path) {
                try fileManager.removeItem(at: transcriptsDirectory)
            }
            
            createDirectoriesIfNeeded()
        } catch {
            throw StorageError.deleteFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Transcript File Management
    
    private func saveTranscripts(for topic: Topic) async throws {
        let topicDir = transcriptsDirectory.appendingPathComponent(topic.id.uuidString, isDirectory: true)
        try? fileManager.createDirectory(at: topicDir, withIntermediateDirectories: true)
        
        for recording in topic.recordings {
            if let transcript = recording.transcript {
                let transcriptFile = topicDir.appendingPathComponent("\(recording.id.uuidString).txt")
                try transcript.write(to: transcriptFile, atomically: true, encoding: .utf8)
            }
            
            if let summary = recording.summary {
                let summaryFile = topicDir.appendingPathComponent("\(recording.id.uuidString)_summary.txt")
                try summary.write(to: summaryFile, atomically: true, encoding: .utf8)
            }
            
            if let points = recording.summaryPoints {
                let pointsFile = topicDir.appendingPathComponent("\(recording.id.uuidString)_points.json")
                let data = try JSONEncoder().encode(points)
                try data.write(to: pointsFile)
            }
        }
        
        if let consolidatedSummary = topic.consolidatedSummary {
            let summaryFile = topicDir.appendingPathComponent("consolidated_summary.txt")
            try consolidatedSummary.write(to: summaryFile, atomically: true, encoding: .utf8)
        }
        
        if let consolidatedPoints = topic.consolidatedPoints {
            let pointsFile = topicDir.appendingPathComponent("consolidated_points.json")
            let data = try JSONEncoder().encode(consolidatedPoints)
            try data.write(to: pointsFile)
        }
    }
    
    private func loadTranscripts(for topic: Topic) async throws -> Topic {
        var updatedTopic = topic
        let topicDir = transcriptsDirectory.appendingPathComponent(topic.id.uuidString, isDirectory: true)
        
        guard fileManager.fileExists(atPath: topicDir.path) else {
            return topic
        }
        
        for i in updatedTopic.recordings.indices {
            let recording = updatedTopic.recordings[i]
            
            let transcriptFile = topicDir.appendingPathComponent("\(recording.id.uuidString).txt")
            if fileManager.fileExists(atPath: transcriptFile.path) {
                updatedTopic.recordings[i].transcript = try? String(contentsOf: transcriptFile, encoding: .utf8)
            }
            
            let summaryFile = topicDir.appendingPathComponent("\(recording.id.uuidString)_summary.txt")
            if fileManager.fileExists(atPath: summaryFile.path) {
                updatedTopic.recordings[i].summary = try? String(contentsOf: summaryFile, encoding: .utf8)
            }
            
            let pointsFile = topicDir.appendingPathComponent("\(recording.id.uuidString)_points.json")
            if fileManager.fileExists(atPath: pointsFile.path),
               let data = try? Data(contentsOf: pointsFile) {
                updatedTopic.recordings[i].summaryPoints = try? JSONDecoder().decode([String].self, from: data)
            }
        }
        
        let consolidatedSummaryFile = topicDir.appendingPathComponent("consolidated_summary.txt")
        if fileManager.fileExists(atPath: consolidatedSummaryFile.path) {
            updatedTopic.consolidatedSummary = try? String(contentsOf: consolidatedSummaryFile, encoding: .utf8)
        }
        
        let consolidatedPointsFile = topicDir.appendingPathComponent("consolidated_points.json")
        if fileManager.fileExists(atPath: consolidatedPointsFile.path),
           let data = try? Data(contentsOf: consolidatedPointsFile) {
            updatedTopic.consolidatedPoints = try? JSONDecoder().decode([String].self, from: data)
        }
        
        return updatedTopic
    }
}
