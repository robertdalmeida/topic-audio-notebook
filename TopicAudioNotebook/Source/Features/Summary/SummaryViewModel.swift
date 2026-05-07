import Foundation
import Combine

@Observable
@MainActor
final class SummaryViewModel {
    
    // MARK: - State
    
    private let stateManager = SummarizationStateManager.shared
    var displayMode: SummaryDisplayMode = .points
    private(set) var topic: Topic?
    private(set) var isGeneratingKeyPoints = false
    private(set) var isGeneratingSummary = false
    private(set) var isModelLoading = true
    
    // MARK: - Dependencies
    
    private let topicId: UUID
    private let repository: TopicRepository
    private let factory: SummarizationServiceFactory
    private var cancellables = Set<AnyCancellable>()
    
    var hasSummary: Bool {
        topic?.consolidatedSummary != nil || topic?.consolidatedPoints != nil
    }
    
    var hasKeyPoints: Bool {
        topic?.consolidatedPoints != nil && !(topic?.consolidatedPoints?.isEmpty ?? true)
    }
    
    var hasFullSummary: Bool {
        topic?.consolidatedSummary != nil && !(topic?.consolidatedSummary?.isEmpty ?? true)
    }
    
    var isGenerating: Bool {
        isGeneratingKeyPoints || isGeneratingSummary
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
        factory: SummarizationServiceFactory = .shared
    ) {
        self.topicId = topicId
        self.repository = repository
        self.factory = factory
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
        isModelLoading = true
        await stateManager.preloadModelIfNeeded()
        isModelLoading = false
    }
    
    func generateKeyPoints() async {
        isGeneratingKeyPoints = true
        await repository.generateConsolidatedKeyPoints(for: topicId)
        isGeneratingKeyPoints = false
    }
    
    func generateFullSummary() async {
        isGeneratingSummary = true
        await repository.generateConsolidatedSummary(for: topicId)
        isGeneratingSummary = false
    }
    
}
