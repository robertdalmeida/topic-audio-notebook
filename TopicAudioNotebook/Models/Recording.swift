import Foundation

struct Recording: Identifiable, Codable {
    let id: UUID
    var title: String
    var fileURL: URL
    var duration: TimeInterval
    var transcript: String?
    var summary: String?
    var summaryPoints: [String]?
    var transcriptionStatus: TranscriptionStatus
    var summaryStatus: SummaryStatus
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        fileURL: URL,
        duration: TimeInterval = 0,
        transcript: String? = nil,
        summary: String? = nil,
        summaryPoints: [String]? = nil,
        transcriptionStatus: TranscriptionStatus = .pending,
        summaryStatus: SummaryStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.fileURL = fileURL
        self.duration = duration
        self.transcript = transcript
        self.summary = summary
        self.summaryPoints = summaryPoints
        self.transcriptionStatus = transcriptionStatus
        self.summaryStatus = summaryStatus
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

enum SummaryStatus: String, Codable {
    case pending = "Pending"
    case inProgress = "Summarizing..."
    case completed = "Completed"
    case failed = "Failed"
    case notAvailable = "No API Key"
    
    var iconName: String {
        switch self {
        case .pending: return "clock"
        case .inProgress: return "brain"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        case .notAvailable: return "key.slash"
        }
    }
}
