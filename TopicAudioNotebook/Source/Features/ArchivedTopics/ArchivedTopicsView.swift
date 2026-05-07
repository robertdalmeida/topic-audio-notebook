import SwiftUI

struct ArchivedTopicsView: View {
    @ObservedObject var repository: TopicRepository
    @Environment(\.dismiss) private var dismiss
    
    @State private var topicToDelete: Topic?
    @State private var topicToRestore: Topic?
    
    var body: some View {
        Group {
            if repository.archivedTopics.isEmpty {
                ContentUnavailableView {
                    Label("No Archived Topics", systemImage: "archivebox")
                } description: {
                    Text("Topics you archive will appear here")
                }
            } else {
                List {
                    ForEach(repository.archivedTopics) { topic in
                        NavigationLink {
                            ArchivedTopicDetailWrapper(topicId: topic.id, repository: repository)
                        } label: {
                            ArchivedTopicRow(topic: topic)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                topicToDelete = topic
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                topicToRestore = topic
                            } label: {
                                Label("Restore", systemImage: "arrow.uturn.backward")
                            }
                            .tint(.blue)
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Archived Topics")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $topicToDelete) { topic in
            DeleteTopicConfirmationView(
                topicName: topic.name,
                onConfirm: {
                    repository.deleteTopic(topic)
                    topicToDelete = nil
                },
                onCancel: {
                    topicToDelete = nil
                }
            )
        }
        .fullScreenCover(item: $topicToRestore) { topic in
            RestoreTopicConfirmationView(
                topicName: topic.name,
                onConfirm: {
                    repository.unarchiveTopic(topic)
                    topicToRestore = nil
                },
                onCancel: {
                    topicToRestore = nil
                }
            )
        }
    }
}

struct ArchivedTopicRow: View {
    let topic: Topic
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(colorForTopic(topic.color))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "archivebox.fill")
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(topic.recordings.count)", systemImage: "waveform")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if let archivedAt = topic.archivedAt {
                        Text("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func colorForTopic(_ color: TopicColor) -> Color {
        switch color {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}

struct ArchivedTopicDetailWrapper: View {
    let topicId: UUID
    @ObservedObject var repository: TopicRepository
    @Environment(\.dismiss) private var dismiss
    
    private var topic: Topic? {
        repository.topics.first { $0.id == topicId }
    }
    
    var body: some View {
        if let topic = topic {
            TopicDetailView(
                viewModel: TopicDetailViewModel(topicId: topic.id, repository: repository),
                isArchivedContext: true
            )
        } else {
            ContentUnavailableView {
                Label("Topic Not Found", systemImage: "folder.badge.questionmark")
            } description: {
                Text("This topic may have been deleted")
            }
        }
    }
}

#Preview {
    let repository = TopicRepository()
    return NavigationStack {
        ArchivedTopicsView(repository: repository)
    }
}
