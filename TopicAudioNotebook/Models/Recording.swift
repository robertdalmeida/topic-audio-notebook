import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    var title: String
    var fileURL: URL
    var duration: TimeInterval
    var transcript: String?
    var transcriptionStatus: TranscriptionStatus
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        fileURL: URL,
        duration: TimeInterval = 0,
        transcript: String? = nil,
        transcriptionStatus: TranscriptionStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.transcript = transcript
        self.transcriptionStatus = transcriptionStatus
        self.createdAt = createdAt
    }
    
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

enum TranscriptionStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "Transcribing..."
    case completed = "Completed"
    case failed = "Failed"
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "waveform"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }
}
