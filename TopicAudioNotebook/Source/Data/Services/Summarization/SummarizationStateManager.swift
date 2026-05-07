import Foundation

enum SummarizationModelState: Equatable, Sendable {
    case idle
    case loading(progress: Double)
    case ready
    case failed(String)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var isReady: Bool {
        self == .ready
    }
    
    var progress: Double {
        if case .loading(let progress) = self { return progress }
        return isReady ? 1.0 : 0.0
    }
}

@Observable
@MainActor
final class SummarizationStateManager {
    static let shared = SummarizationStateManager()
    
    private(set) var modelState: SummarizationModelState = .idle
    private(set) var isSummarizing = false
    
    private let factory: SummarizationServiceFactory
    
    var isSummarizationEnabled: Bool {
        factory.currentProvider.isEnabled
    }
    
    var canSummarize: Bool {
        isSummarizationEnabled && !isSummarizing && (modelState == .ready || modelState == .idle)
    }
    
    var statusMessage: String? {
        switch modelState {
        case .idle:
            return nil
        case .loading(let progress):
            return "Loading model... \(Int(progress * 100))%"
        case .ready:
            return nil
        case .failed(let message):
            return message
        }
    }
    
    private init(factory: SummarizationServiceFactory = .shared) {
        self.factory = factory
    }
    
    func checkModelState() async {
        let service = factory.currentService
        
        guard let loadable = service as? LoadableSummarizationService else {
            modelState = .ready
            return
        }
        
        let isLoaded = await loadable.isLoaded
        let isLoading = await loadable.isLoading
        let progress = await loadable.loadingProgress
        
        if isLoaded {
            modelState = .ready
        } else if isLoading {
            modelState = .loading(progress: progress)
        } else {
            modelState = .idle
        }
    }
    
    func preloadModelIfNeeded() async {
        let service = factory.currentService
        
        guard let loadable = service as? LoadableSummarizationService else {
            modelState = .ready
            return
        }
        
        let isLoaded = await loadable.isLoaded
        if isLoaded {
            modelState = .ready
            return
        }
        
        modelState = .loading(progress: 0.0)
        
        do {
            try await loadable.preloadModel { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.modelState = .loading(progress: progress)
                }
            }
            modelState = .ready
        } catch {
            modelState = .failed("Failed to load model: \(error.localizedDescription)")
        }
    }
    
    func performSummarization<T>(_ operation: () async throws -> T) async throws -> T {
        isSummarizing = true
        defer { isSummarizing = false }
        
        if modelState == .idle {
            await preloadModelIfNeeded()
        }
        
        return try await operation()
    }
    
    func resetState() {
        modelState = .idle
        isSummarizing = false
    }
}
