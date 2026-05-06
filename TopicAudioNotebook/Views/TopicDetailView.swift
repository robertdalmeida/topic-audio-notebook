import SwiftUI

struct TopicDetailView: View {
    @EnvironmentObject var topicStore: TopicStore
    @StateObject private var recorder = AudioRecorder()
    @State private var showingSummary = false
    @State private var isConsolidating = false
    @State private var isGeneratingTopicSummary = false
    @State private var isRecording = false
    @State private var currentRecordingURL: URL?
    
    let topic: Topic
    
    private var currentTopic: Topic {
        topicStore.topics.first { $0.id == topic.id } ?? topic
    }
    
    var body: some View {
        ZStack {
            List {
                descriptionSection
                statsSection
                summarySection
                recordingsSection
            }
            .listStyle(.insetGrouped)
            
            VStack {
                Spacer()
                recordButton
            }
        }
        .navigationTitle(currentTopic.name)
        .toolbar { topToolbar }
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
    
    // MARK: - Record Button
    
    private var recordButton: some View {
        Button {
            if isRecording {
                stopRecordingAndSave()
            } else {
                startRecording()
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isRecording ? Color.red : Color.blue)
                        .frame(width: 56, height: 56)
                    
                    if isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                
                if isRecording {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recording...")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(recorder.formattedTime)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                } else {
                    Text("Record")
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isRecording ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
            )
        }
        .buttonStyle(.plain)
        .padding(.bottom, 20)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
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
    
    private func startRecording() {
        Task {
            let directory = topicStore.getRecordingsDirectory()
            currentRecordingURL = await recorder.startRecording(to: directory)
            if currentRecordingURL != nil {
                isRecording = true
            }
        }
    }
    
    private func stopRecordingAndSave() {
        guard let result = recorder.stopRecording(),
              let _ = currentRecordingURL else {
            isRecording = false
            return
        }
        
        let title = generateRecordingTitle()
        topicStore.addRecording(to: topic.id, title: title, fileURL: result.0, duration: result.1)
        
        isRecording = false
        currentRecordingURL = nil
    }
    
    private func generateRecordingTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: Date())
        
        let recordingNumber = currentTopic.recordings.count + 1
        return "\(currentTopic.name) #\(recordingNumber) - \(dateStr), \(timeStr)"
    }
}

#Preview {
    NavigationStack {
        TopicDetailView(topic: Topic(name: "Sample Topic", description: "A test topic"))
    }
    .environmentObject(TopicStore())
}
