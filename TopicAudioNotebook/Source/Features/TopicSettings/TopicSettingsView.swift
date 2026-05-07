import SwiftUI

struct TopicSettingsView: View {
    let topic: Topic
    let repository: TopicRepository
    let onDismiss: () -> Void
    let isArchivedContext: Bool
    let onTopicArchived: (() -> Void)?
    let onTopicDeleted: (() -> Void)?
    let onTopicRestored: (() -> Void)?
    
    @State private var name: String
    @State private var description: String
    @State private var selectedColor: TopicColor
    @State private var showingDeleteConfirmation = false
    @State private var showingArchiveConfirmation = false
    @State private var showingRestoreConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    init(
        topic: Topic,
        repository: TopicRepository,
        isArchivedContext: Bool = false,
        onDismiss: @escaping () -> Void,
        onTopicArchived: (() -> Void)? = nil,
        onTopicDeleted: (() -> Void)? = nil,
        onTopicRestored: (() -> Void)? = nil
    ) {
        self.topic = topic
        self.repository = repository
        self.isArchivedContext = isArchivedContext
        self.onDismiss = onDismiss
        self.onTopicArchived = onTopicArchived
        self.onTopicDeleted = onTopicDeleted
        self.onTopicRestored = onTopicRestored
        _name = State(initialValue: topic.name)
        _description = State(initialValue: topic.description)
        _selectedColor = State(initialValue: topic.color)
    }
    
    private var showDeleteOption: Bool {
        isArchivedContext
    }
    
    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private var hasChanges: Bool {
        name != topic.name || description != topic.description || selectedColor != topic.color
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Topic Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(TopicColor.allCases, id: \.self) { color in
                            ColorButton(color: color, isSelected: selectedColor == color) {
                                selectedColor = color
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                if !topic.isArchived {
                    Section {
                        Button {
                            showingArchiveConfirmation = true
                        } label: {
                            Label("Archive Topic", systemImage: "archivebox")
                        }
                    }
                }
                
                if topic.isArchived && isArchivedContext {
                    Section {
                        Button {
                            showingRestoreConfirmation = true
                        } label: {
                            Label("Restore Topic", systemImage: "arrow.uturn.backward")
                        }
                    }
                }
                
                if showDeleteOption {
                    Section {
                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Topic Permanently", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Topic Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(!canSave || !hasChanges)
                }
            }
            .fullScreenCover(isPresented: $showingArchiveConfirmation) {
                ArchiveTopicConfirmationView(
                    topicName: topic.name,
                    onConfirm: {
                        repository.archiveTopic(topic)
                        showingArchiveConfirmation = false
                        onDismiss()
                        onTopicArchived?()
                    },
                    onCancel: {
                        showingArchiveConfirmation = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showingDeleteConfirmation) {
                DeleteTopicConfirmationView(
                    topicName: topic.name,
                    onConfirm: {
                        repository.deleteTopic(topic)
                        showingDeleteConfirmation = false
                        onDismiss()
                        onTopicDeleted?()
                    },
                    onCancel: {
                        showingDeleteConfirmation = false
                    }
                )
            }
            .fullScreenCover(isPresented: $showingRestoreConfirmation) {
                RestoreTopicConfirmationView(
                    topicName: topic.name,
                    onConfirm: {
                        repository.unarchiveTopic(topic)
                        showingRestoreConfirmation = false
                        onDismiss()
                        onTopicRestored?()
                    },
                    onCancel: {
                        showingRestoreConfirmation = false
                    }
                )
            }
        }
    }
    
    private func saveChanges() {
        var updatedTopic = topic
        updatedTopic.name = name.trimmingCharacters(in: .whitespaces)
        updatedTopic.description = description.trimmingCharacters(in: .whitespaces)
        updatedTopic.color = selectedColor
        repository.updateTopic(updatedTopic)
        onDismiss()
    }
}

#Preview {
    let repository = TopicRepository()
    let topic = Topic(name: "Sample Topic", description: "A test topic")
    return TopicSettingsView(topic: topic, repository: repository, onDismiss: {})
}
