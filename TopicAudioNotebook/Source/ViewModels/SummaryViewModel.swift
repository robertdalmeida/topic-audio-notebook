import Foundation

@Observable
@MainActor
final class SummaryViewModel {
    
    // MARK: - State
    
    enum ViewState: Equatable {
        case loading
        case ready
        case regenerating
        case error(String)
    }
    
    enum ModelLoadingState: Equatable {
        case idle
        case loading(progress: Double)
        case loaded
        case failed(String)
    }
    
    private(set) var viewState: ViewState = .loading
    private(set) var modelLoadingState: ModelLoadingState = .idle
    var displayMode: SummaryDisplayMode = .points
    
    // MARK: - Dependencies
    
    private let topicId: UUID
    private let repository: TopicRepository
    private let factory: SummarizationServiceFactory
    private let regenerateAction: (() async -> Void)?
    
    // MARK: - Computed Properties
    
    var topic: Topic? {
        repository.topics.first { $0.id == topicId }
    }
    
    var hasSummary: Bool {
        topic?.consolidatedSummary != nil || topic?.consolidatedPoints != nil
    }
    
    var canRegenerate: Bool {
        guard regenerateAction != nil else { return false }
        
        switch viewState {
        case .ready:
            return modelLoadingState == .loaded || modelLoadingState == .idle
        default:
            return false
        }
    }
    
    var isRegenerating: Bool {
        viewState == .regenerating
    }
    
    var shareContent: String {
        guard let topic else { return "" }
        var content = "# \(topic.name) - Summary\n\n"
        
        if let points = topic.consolidatedPoints, !points.isEmpty {
            content += "## Key Points\n\n"
            for (index, point) in points.enumerated() {
                content += "\(index + 1). \(point)\n"
            }
            content += "\n"
        }
        
        if let summary = topic.consolidatedSummary {
            content += "## Full Summary\n\n\(summary)"
        }
        
        return content
    }
    
    // MARK: - Initialization
    
    init(
        topicId: UUID,
        repository: TopicRepository,
        factory: SummarizationServiceFactory = .shared,
        regenerateAction: (() async -> Void)? = nil
    ) {
        self.topicId = topicId
        self.repository = repository
        self.factory = factory
        self.regenerateAction = regenerateAction
    }
    
    // MARK: - Actions
    
    func onAppear() async {
        viewState = .loading
        await loadModelIfNeeded()
        viewState = .ready
    }
    
    func regenerateSummary() async {
        guard let regenerateAction else { return }
        
        viewState = .regenerating
        await regenerateAction()
        viewState = .ready
    }
    
    // MARK: - Private Methods
    
    private func loadModelIfNeeded() async {
        let isReady = await factory.isServiceReady()
        
        if isReady {
            modelLoadingState = .loaded
            return
        }
        
        guard factory.requiresPreloading() else {
            modelLoadingState = .loaded
            return
        }
        
        modelLoadingState = .loading(progress: 0.0)
        
        do {
            try await factory.preloadCurrentService { [weak self] progress in
                Task { @MainActor [weak self] in
                    self?.modelLoadingState = .loading(progress: progress)
                }
            }
            modelLoadingState = .loaded
        } catch {
            modelLoadingState = .failed("Failed to load model: \(error.localizedDescription)")
        }
    }
}
