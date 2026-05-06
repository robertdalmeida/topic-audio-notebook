import SwiftUI

struct ContentView: View {
    @EnvironmentObject var repository: TopicRepository
    @StateObject var viewModel: TopicsListViewModel
    
    var body: some View {
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

struct EmptyStateView: View {
    let onAddTopic: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 80))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("No Topics Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create your first topic to start\norganizing audio recordings")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: onAddTopic) {
                Label("Create Topic", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

struct TopicListView: View {
    let topics: [Topic]
    let onDelete: (IndexSet) -> Void
    let repository: TopicRepository
    
    var body: some View {
        List {
            ForEach(topics) { topic in
                NavigationLink(destination: TopicDetailView(
                    viewModel: TopicDetailViewModel(topicId: topic.id, repository: repository)
                )) {
                    TopicRowView(topic: topic)
                }
            }
            .onDelete(perform: onDelete)
        }
        .listStyle(.insetGrouped)
    }
}

struct TopicRowView: View {
    let topic: Topic
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(colorForTopic(topic.color))
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "folder.fill")
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(topic.name)
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Label("\(topic.recordings.count)", systemImage: "waveform")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    if topic.pendingTranscriptionsCount > 0 {
                        Label("\(topic.pendingTranscriptionsCount) pending", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    
                    if topic.consolidatedSummary != nil {
                        Image(systemName: "doc.text.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            
            Spacer()
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

#Preview {
    let repository = TopicRepository()
    return ContentView(viewModel: TopicsListViewModel(repository: repository))
        .environmentObject(repository)
}
