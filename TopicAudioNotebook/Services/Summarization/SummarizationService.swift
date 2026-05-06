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
    case foundationModels = "Apple Intelligence"
    case openAI = "OpenAI"
    
    var description: String {
        switch self {
        case .onDevice:
            return "Uses Apple's NaturalLanguage framework for privacy-focused, offline summarization"
        case .foundationModels:
            return "Uses Apple Intelligence for high-quality on-device AI summaries (iOS 26+)"
        case .openAI:
            return "Uses OpenAI GPT-4 for high-quality AI summaries (requires API key)"
        }
    }
    
    var icon: String {
        switch self {
        case .onDevice:
            return "iphone"
        case .foundationModels:
            return "apple.intelligence"
        case .openAI:
            return "cloud"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .onDevice:
            return true
        case .foundationModels:
            return FoundationModelsAvailability.isAvailable
        case .openAI:
            return true
        }
    }
    
    static var availableProviders: [SummarizationProvider] {
        allCases.filter { $0.isAvailable }
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
