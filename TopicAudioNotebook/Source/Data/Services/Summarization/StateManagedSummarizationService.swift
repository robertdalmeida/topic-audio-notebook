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
    func generateKeyPoints(_ transcripts: [String]) async throws -> [String] {
        try await stateManager.performSummarization {
            try await self.factory.currentService.generateKeyPoints(transcripts)
        }
    }
    
    @MainActor
    func generateFullSummary(_ transcripts: [String]) async throws -> String {
        try await stateManager.performSummarization {
            try await self.factory.currentService.generateFullSummary(transcripts)
        }
    }
    
    @MainActor
    func preloadIfNeeded() async {
        await stateManager.preloadModelIfNeeded()
    }
}
