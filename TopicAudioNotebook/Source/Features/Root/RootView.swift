import SwiftUI

struct RootView: View {
    @EnvironmentObject var repository: TopicRepository
    @StateObject private var viewModel: TopicsListViewModel
    @State private var selectedTopicId: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    init(repository: TopicRepository) {
        _viewModel = StateObject(wrappedValue: TopicsListViewModel(repository: repository))
    }
    
    var body: some View {
        if horizontalSizeClass == .regular {
            splitViewLayout
        } else {
            stackLayout
        }
    }
    
    // MARK: - Split View Layout (iPad/Mac)
    
    private var splitViewLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(
                viewModel: viewModel,
                selectedTopicId: $selectedTopicId,
                repository: repository
            )
        } detail: {
            NavigationStack {
                if let topicId = selectedTopicId {
                    TopicDetailView(
                        viewModel: TopicDetailViewModel(topicId: topicId, repository: repository)
                    )
                } else {
                    NoSelectionView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    // MARK: - Stack Layout (iPhone)
    
    private var stackLayout: some View {
        NavigationStack {
            ZStack {
                if viewModel.topics.isEmpty {
                    EmptyStateView(onAddTopic: viewModel.presentAddTopic)
                } else {
                    TopicListView(
                        topics: viewModel.topics,
                        onDelete: viewModel.deleteTopic,
                        repository: repository
                    )
                }
            }
            .navigationTitle("Topics")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: viewModel.presentSettings) {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.presentAddTopic) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddTopic) {
                AddTopicView(viewModel: AddTopicViewModel(repository: repository) {
                    viewModel.showingAddTopic = false
                })
            }
            .sheet(isPresented: $viewModel.showingSettings) {
                SettingsView(viewModel: SettingsViewModel(repository: repository))
            }
        }
    }
}

// MARK: - Sidebar View

private struct SidebarView: View {
    @ObservedObject var viewModel: TopicsListViewModel
    @Binding var selectedTopicId: UUID?
    let repository: TopicRepository
    
    var body: some View {
        List(selection: $selectedTopicId) {
            ForEach(viewModel.topics) { topic in
                SidebarTopicRow(topic: topic)
                    .tag(topic.id)
            }
            .onDelete(perform: viewModel.deleteTopic)
        }
        .listStyle(.sidebar)
        .navigationTitle("Topics")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.presentAddTopic) {
                    Image(systemName: "plus")
                }
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: viewModel.presentSettings) {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddTopic) {
            AddTopicView(viewModel: AddTopicViewModel(repository: repository) {
                viewModel.showingAddTopic = false
            })
        }
        .sheet(isPresented: $viewModel.showingSettings) {
            SettingsView(viewModel: SettingsViewModel(repository: repository))
        }
        .overlay {
            if viewModel.topics.isEmpty {
                ContentUnavailableView {
                    Label("No Topics", systemImage: "folder.badge.plus")
                } description: {
                    Text("Create a topic to get started")
                } actions: {
                    Button("Create Topic", action: viewModel.presentAddTopic)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

private struct SidebarTopicRow: View {
    let topic: Topic
    
    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(colorForTopic(topic.color))
                .frame(width: 10, height: 10)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(topic.name)
                    .font(.body)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label("\(topic.recordings.count)", systemImage: "waveform")
                    Label("\(topic.notes.count)", systemImage: "note.text")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
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

// MARK: - No Selection View

private struct NoSelectionView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Topic Selected", systemImage: "folder")
        } description: {
            Text("Select a topic from the sidebar to view its details")
        }
    }
}

#Preview {
    let repository = TopicRepository()
    return RootView(repository: repository)
        .environmentObject(repository)
}
