import Foundation

struct Note: Identifiable, Codable {
    let id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, content, createdAt, updatedAt, isArchived
    }
    
    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        isArchived = try container.decodeIfPresent(Bool.self, forKey: .isArchived) ?? false
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updatedAt)
    }
    
    var preview: String {
        let lines = content.components(separatedBy: .newlines)
        let firstLine = lines.first ?? ""
        return String(firstLine.prefix(100))
    }
}
