import Foundation

@MainActor
final class AddTopicViewModel: ObservableObject {
    @Published var name = ""
    @Published var description = ""
    @Published var selectedColor: TopicColor = .blue
    
    private let repository: TopicRepository
    private let onDismiss: () -> Void
    
    var canCreate: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(repository: TopicRepository, onDismiss: @escaping () -> Void) {
        self.repository = repository
        self.onDismiss = onDismiss
    }
    
    // MARK: - Actions
    
    func createTopic() {
        repository.addTopic(name: name, description: description, color: selectedColor)
        onDismiss()
    }
    
    func cancel() {
        onDismiss()
    }
    
    func selectColor(_ color: TopicColor) {
        selectedColor = color
    }
}
