import Foundation

struct SummaryResult: Sendable {
    let summary: String
    let points: [String]
    
    init(summary: String, points: [String] = []) {
        self.summary = summary
        self.points = points
    }
}

enum SummarizationProvider: String, CaseIterable, Codable {
    case onDevice = "On-Device"
    case openAI = "OpenAI"
    
    var description: String {
        switch self {
        case .onDevice:
            return "Uses Apple's NaturalLanguage framework for privacy-focused, offline summarization"
        case .openAI:
            return "Uses OpenAI GPT-4 for high-quality AI summaries (requires API key)"
        }
    }
    
    var icon: String {
        switch self {
        case .onDevice:
            return "iphone"
        case .openAI:
            return "cloud"
        }
    }
}

enum SummarizationError: LocalizedError {
    case noAPIKey
    case requestFailed(String)
    case invalidResponse
    case textTooShort
    case processingFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noAPIKey:
            return "OpenAI API key not configured"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .invalidResponse:
            return "Invalid response from service"
        case .textTooShort:
            return "Text is too short to summarize"
        case .processingFailed(let message):
            return "Processing failed: \(message)"
        }
    }
}

protocol SummarizationService: Sendable {
    func summarizeRecording(_ transcript: String) async throws -> SummaryResult
    func consolidateTranscripts(_ transcripts: [String]) async throws -> SummaryResult
    var providerType: SummarizationProvider { get }
}
