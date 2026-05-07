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
        topic?.consolidatedSummary != nil || topic?.consolidatedPoints != nil || hasContent
    }
    
    var hasContent: Bool {
        guard let topic else { return false }
        return !topic.activeRecordings.isEmpty || !topic.activeNotes.isEmpty
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
        
        switch displayMode {
        case .points:
            return shareKeyPointsContent(topic: topic)
        case .longForm:
            return shareLongFormContent(topic: topic)
        case .fullContent:
            return shareFullContent(topic: topic)
        }
    }
    
    private func shareKeyPointsContent(topic: Topic) -> String {
        var content = "# \(topic.name) - Key Points\n\n"
        
        if let points = topic.consolidatedPoints, !points.isEmpty {
            for (index, point) in points.enumerated() {
                content += "\(index + 1). \(point)\n"
            }
        }
        
        return content
    }
    
    private func shareLongFormContent(topic: Topic) -> String {
        var content = "# \(topic.name) - Summary\n\n"
        
        if let summary = topic.consolidatedSummary {
            content += summary
        }
        
        return content
    }
    
    private func shareFullContent(topic: Topic) -> String {
        var content = "# \(topic.name) - All Content\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        var items: [(date: Date, text: String)] = []
        
        for recording in topic.activeRecordings {
            var itemText = "## 🎙️ Recording: \(recording.title)\n"
            itemText += "📅 \(dateFormatter.string(from: recording.createdAt))"
            
            let minutes = Int(recording.duration) / 60
            let seconds = Int(recording.duration) % 60
            itemText += " • ⏱️ \(String(format: "%d:%02d", minutes, seconds))\n\n"
            
            if let transcript = recording.transcript, !transcript.isEmpty {
                itemText += "### Transcription\n\(transcript)\n\n"
            } else {
                itemText += "*No transcription available*\n\n"
            }
            
            itemText += "---\n\n"
            items.append((recording.createdAt, itemText))
        }
        
        for note in topic.activeNotes {
            var itemText = "## 📝 Note\n"
            itemText += "📅 \(dateFormatter.string(from: note.createdAt))\n\n"
            itemText += "\(note.content)\n\n"
            itemText += "---\n\n"
            items.append((note.createdAt, itemText))
        }
        
        items.sort { $0.date > $1.date }
        
        for item in items {
            content += item.text
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
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
