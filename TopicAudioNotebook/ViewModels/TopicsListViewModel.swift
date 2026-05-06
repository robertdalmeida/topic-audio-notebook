import Foundation
import Combine

@MainActor
final class TopicsListViewModel: ObservableObject {
    @Published private(set) var topics: [Topic] = []
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
            .assign(to: &$topics)
    }
    
    // MARK: - Actions
    
    func deleteTopic(at offsets: IndexSet) {
        for index in offsets {
            repository.deleteTopic(topics[index])
        }
    }
    
    func presentAddTopic() {
        showingAddTopic = true
    }
    
    func presentSettings() {
        showingSettings = true
    }
}
