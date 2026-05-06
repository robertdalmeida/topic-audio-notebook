import Foundation

final class StateManagedSummarizationService: @unchecked Sendable {
    private let factory: SummarizationServiceFactory
    private let stateManager: SummarizationStateManager
    
    init(
        factory: SummarizationServiceFactory = .shared,
        stateManager: SummarizationStateManager
    ) {
        self.factory = factory
        self.stateManager = stateManager
    }
    
    var currentService: any SummarizationService {
        factory.currentService
    }
    
    var providerType: SummarizationProvider {
        factory.currentProvider
    }
    
    @MainActor
    func summarizeRecording(_ transcript: String) async throws -> SummaryResult {
        try await stateManager.performSummarization {
            try await self.factory.currentService.summarizeRecording(transcript)
        }
    }
    
    @MainActor
    func consolidateTranscripts(_ transcripts: [String]) async throws -> SummaryResult {
        try await stateManager.performSummarization {
            try await self.factory.currentService.consolidateTranscripts(transcripts)
        }
    }
    
    @MainActor
    func preloadIfNeeded() async {
        await stateManager.preloadModelIfNeeded()
    }
}
