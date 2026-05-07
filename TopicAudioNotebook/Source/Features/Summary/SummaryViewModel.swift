import Foundation
import Combine

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
    
    private(set) var viewState: ViewState = .loading
    private let stateManager = SummarizationStateManager.shared
    var displayMode: SummaryDisplayMode = .points
    private(set) var topic: Topic?
    
    // MARK: - Dependencies
    
    private let topicId: UUID
    private let repository: TopicRepository
    private let factory: SummarizationServiceFactory
    private let regenerateAction: (() async -> Void)?
    private var cancellables = Set<AnyCancellable>()
    
    var hasSummary: Bool {
        topic?.consolidatedSummary != nil || topic?.consolidatedPoints != nil
    }
    
    var canRegenerate: Bool {
        regenerateAction != nil && viewState == .ready
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
        self.topic = repository.topics.first { $0.id == topicId }
        
        setupBindings()
    }
    
    private func setupBindings() {
        repository.$topics
            .map { [topicId] topics in
                topics.first { $0.id == topicId }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] topic in
                self?.topic = topic
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    func onAppear() async {
        if hasSummary {
            viewState = .ready
            await stateManager.preloadModelIfNeeded()
        } else {
            viewState = .loading
            await stateManager.preloadModelIfNeeded()
            viewState = .ready
        }
    }
    
    func regenerateSummary() async {
        guard let regenerateAction else { return }
        
        viewState = .regenerating
        await regenerateAction()
        viewState = .ready
    }
    
}
