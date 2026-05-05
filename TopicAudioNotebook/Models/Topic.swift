import Foundation

struct Topic: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var recordings: [Recording]
    var consolidatedSummary: String?
    var createdAt: Date
    var updatedAt: Date
    var color: TopicColor
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        recordings: [Recording] = [],
        consolidatedSummary: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        color: TopicColor = .blue
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.recordings = recordings
        self.consolidatedSummary = consolidatedSummary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.color = color
    }
    
    var transcribedRecordingsCount: Int {
        recordings.filter { $0.transcriptionStatus == .completed }.count
    }
    
    var pendingTranscriptionsCount: Int {
        recordings.filter { $0.transcriptionStatus == .pending || $0.transcriptionStatus == .inProgress }.count
    }
    
    var allTranscripts: [String] {
        recordings.compactMap { $0.transcript }
    }
    
    var totalDuration: TimeInterval {
        recordings.reduce(0) { $0 + $1.duration }
    }
}

enum TopicColor: String, Codable, CaseIterable {
    case blue, purple, green, orange, red, pink, teal, indigo
    
    var colorName: String {
        rawValue.capitalized
    }
}
