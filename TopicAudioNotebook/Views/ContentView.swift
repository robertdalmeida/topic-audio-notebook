import SwiftUI

struct ContentView: View {
    @EnvironmentObject var topicStore: TopicStore
    @State private var showingAddTopic = false
    @State private var showingSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                if topicStore.topics.isEmpty {
                    EmptyStateView(showingAddTopic: $showingAddTopic)
                } else {
                    TopicListView(showingAddTopic: $showingAddTopic)
                }
            }
            .navigationTitle("Topics")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gear")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddTopic = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddTopic) {
                AddTopicView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
}

struct EmptyStateView: View {
    @Binding var showingAddTopic: Bool
    
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
            
            Button {
                showingAddTopic = true
            } label: {
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
    @EnvironmentObject var topicStore: TopicStore
    @Binding var showingAddTopic: Bool
    
    var body: some View {
        List {
            ForEach(topicStore.topics) { topic in
                NavigationLink(destination: TopicDetailView(topic: topic)) {
                    TopicRowView(topic: topic)
                }
            }
            .onDelete(perform: deleteTopic)
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteTopic(at offsets: IndexSet) {
        for index in offsets {
            topicStore.deleteTopic(topicStore.topics[index])
        }
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
    ContentView()
        .environmentObject(TopicStore())
}
