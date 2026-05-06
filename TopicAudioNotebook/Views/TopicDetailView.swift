import SwiftUI

struct TopicDetailView: View {
    @EnvironmentObject var topicStore: TopicStore
    @State private var showingRecorder = false
    @State private var showingSummary = false
    @State private var isConsolidating = false
    @State private var isGeneratingTopicSummary = false
    
    let topic: Topic
    
    private var currentTopic: Topic {
        topicStore.topics.first { $0.id == topic.id } ?? topic
    }
    
    var body: some View {
        List {
            descriptionSection
            statsSection
            summarySection
            recordingsSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(currentTopic.name)
        .toolbar { bottomToolbar }
        .sheet(isPresented: $showingRecorder) {
            RecordingView(topicId: topic.id)
        }
        .sheet(isPresented: $showingSummary) {
            SummaryView(topic: currentTopic)
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var descriptionSection: some View {
        if !currentTopic.description.isEmpty {
            Section {
                Text(currentTopic.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var statsSection: some View {
        Section {
            TopicStatsSection(
                recordingsCount: currentTopic.recordings.count,
                transcribedCount: currentTopic.transcribedRecordingsCount,
                formattedDuration: formattedTotalDuration
            )
        }
    }
    
    private var summarySection: some View {
        Section {
            TopicSummarySection(
                summary: currentTopic.consolidatedSummary,
                points: currentTopic.consolidatedPoints,
                transcribedCount: currentTopic.transcribedRecordingsCount,
                isGenerating: isGeneratingTopicSummary || isConsolidating,
                onGenerate: generateTopicSummary
            )
        } header: {
            HStack {
                Text("Topic Summary")
                Spacer()
                if currentTopic.consolidatedSummary != nil {
                    Button { showingSummary = true } label: {
                        Text("View Full")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var recordingsSection: some View {
        Section {
            if currentTopic.recordings.isEmpty {
                ContentUnavailableView {
                    Label("No Recordings", systemImage: "waveform")
                } description: {
                    Text("Tap the microphone button to record")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(currentTopic.recordings) { recording in
                    NavigationLink(destination: RecordingDetailView(recording: recording, topicId: topic.id)) {
                        RecordingRowView(recording: recording, topicId: topic.id)
                    }
                }
                .onDelete(perform: deleteRecording)
            }
        } header: {
            Text("Recordings")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            Button { showingRecorder = true } label: {
                Label("Record", systemImage: "mic.circle.fill")
                    .font(.title2)
            }
            
            Spacer()
            
            Button(action: consolidate) {
                if isConsolidating {
                    ProgressView()
                } else {
                    Label("Consolidate", systemImage: "doc.on.doc")
                }
            }
            .disabled(currentTopic.transcribedRecordingsCount == 0 || isConsolidating)
        }
    }
    
    // MARK: - Helpers
    
    private var formattedTotalDuration: String {
        let total = currentTopic.totalDuration
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let recording = currentTopic.recordings[index]
            topicStore.deleteRecording(recording, from: topic.id)
        }
    }
    
    private func consolidate() {
        isConsolidating = true
        Task {
            await topicStore.consolidateSummary(for: topic.id)
            isConsolidating = false
            if topicStore.topics.first(where: { $0.id == topic.id })?.consolidatedSummary != nil {
                showingSummary = true
            }
        }
    }
    
    private func generateTopicSummary() {
        isGeneratingTopicSummary = true
        Task {
            await topicStore.consolidateSummary(for: topic.id)
            isGeneratingTopicSummary = false
        }
    }
}

#Preview {
    NavigationStack {
        TopicDetailView(topic: Topic(name: "Sample Topic", description: "A test topic"))
    }
    .environmentObject(TopicStore())
}
