import Foundation

struct Topic: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String
    var recordings: [Recording]
    var notes: [Note]
    var consolidatedSummary: String?
    var consolidatedPoints: [String]?
    var createdAt: Date
    var updatedAt: Date
    var color: TopicColor
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, recordings, notes
        case consolidatedSummary, consolidatedPoints
        case createdAt, updatedAt, color
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        recordings: [Recording] = [],
        notes: [Note] = [],
        consolidatedSummary: String? = nil,
        consolidatedPoints: [String]? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        color: TopicColor = .blue
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.recordings = recordings
        self.notes = notes
        self.consolidatedSummary = consolidatedSummary
        self.consolidatedPoints = consolidatedPoints
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.color = color
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.decode(String.self, forKey: .description)
        recordings = try container.decode([Recording].self, forKey: .recordings)
        notes = try container.decodeIfPresent([Note].self, forKey: .notes) ?? []
        consolidatedSummary = try container.decodeIfPresent(String.self, forKey: .consolidatedSummary)
        consolidatedPoints = try container.decodeIfPresent([String].self, forKey: .consolidatedPoints)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        color = try container.decode(TopicColor.self, forKey: .color)
    }
    
    // MARK: - Active Items (non-archived)
    
    var activeRecordings: [Recording] {
        recordings.filter { !$0.isArchived }
    }
    
    var activeNotes: [Note] {
        notes.filter { !$0.isArchived }
    }
    
    // MARK: - Archived Items
    
    var archivedRecordings: [Recording] {
        recordings.filter { $0.isArchived }
    }
    
    var archivedNotes: [Note] {
        notes.filter { $0.isArchived }
    }
    
    var hasArchivedItems: Bool {
        !archivedRecordings.isEmpty || !archivedNotes.isEmpty
    }
    
    // MARK: - Statistics (active items only)
    
    var transcribedRecordingsCount: Int {
        activeRecordings.filter { $0.transcriptionStatus == .completed }.count
    }
    
    var pendingTranscriptionsCount: Int {
        activeRecordings.filter { $0.transcriptionStatus == .pending || $0.transcriptionStatus == .inProgress }.count
    }
    
    var allTranscripts: [String] {
        activeRecordings.compactMap { $0.transcript }
    }
    
    var allNoteContents: [String] {
        activeNotes.map { $0.content }
    }
    
    var allContent: [String] {
        allTranscripts + allNoteContents
    }
    
    var totalDuration: TimeInterval {
        activeRecordings.reduce(0) { $0 + $1.duration }
    }
    
    var hasContentForSummary: Bool {
        transcribedRecordingsCount > 0 || !activeNotes.isEmpty
    }
}

enum TopicColor: String, Codable, CaseIterable {
    case blue, purple, green, orange, red, pink, teal, indigo
    
    var colorName: String {
        rawValue.capitalized
    }
}
