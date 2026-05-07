import Foundation
import Combine

@MainActor
final class TopicsListViewModel: ObservableObject {
    @Published private(set) var topics: [Topic] = []
    @Published private(set) var archivedTopicsCount: Int = 0
    @Published var showingAddTopic = false
    @Published var showingSettings = false
    
    private let repository: TopicRepository
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: TopicRepository) {
        self.repository = repository
        setupBindings()
    }
    
    private func setupBindings() {
        repository.$topics
            .receive(on: DispatchQueue.main)
            .map { $0.filter { !$0.isArchived } }
            .assign(to: &$topics)
        
        repository.$topics
            .receive(on: DispatchQueue.main)
            .map { $0.filter { $0.isArchived }.count }
            .assign(to: &$archivedTopicsCount)
    }
    
    // MARK: - Actions
    
    func archiveTopic(_ topic: Topic) {
        repository.archiveTopic(topic)
    }
    
    func archiveTopic(at offsets: IndexSet) {
        for index in offsets {
            repository.archiveTopic(topics[index])
        }
    }
    
    func presentAddTopic() {
        showingAddTopic = true
    }
    
    func presentSettings() {
        showingSettings = true
    }
}
