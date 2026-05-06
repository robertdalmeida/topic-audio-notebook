import SwiftUI

struct TopicDetailView: View {
    @EnvironmentObject var topicStore: TopicStore
    @State private var showingRecorder = false
    @State private var showingSummary = false
    @State private var isConsolidating = false
    
    let topic: Topic
    
    private var currentTopic: Topic {
        topicStore.topics.first { $0.id == topic.id } ?? topic
    }
    
    var body: some View {
        List {
            if !currentTopic.description.isEmpty {
                Section {
                    Text(currentTopic.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section {
                HStack(spacing: 20) {
                    StatCard(
                        title: "Recordings",
                        value: "\(currentTopic.recordings.count)",
                        icon: "waveform",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Transcribed",
                        value: "\(currentTopic.transcribedRecordingsCount)",
                        icon: "doc.text",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Duration",
                        value: formattedTotalDuration,
                        icon: "clock",
                        color: .orange
                    )
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            
            if currentTopic.consolidatedSummary != nil {
                Section {
                    Button {
                        showingSummary = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.richtext")
                                .font(.title2)
                                .foregroundStyle(.green)
                            
                            VStack(alignment: .leading) {
                                Text("Consolidated Summary")
                                    .font(.headline)
                                Text("Tap to view")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            
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
        .listStyle(.insetGrouped)
        .navigationTitle(currentTopic.name)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    showingRecorder = true
                } label: {
                    Label("Record", systemImage: "mic.circle.fill")
                        .font(.title2)
                }
                
                Spacer()
                
                Button {
                    consolidate()
                } label: {
                    if isConsolidating {
                        ProgressView()
                    } else {
                        Label("Consolidate", systemImage: "doc.on.doc")
                    }
                }
                .disabled(currentTopic.transcribedRecordingsCount == 0 || isConsolidating)
            }
        }
        .sheet(isPresented: $showingRecorder) {
            RecordingView(topicId: topic.id)
        }
        .sheet(isPresented: $showingSummary) {
            SummaryView(topic: currentTopic)
        }
    }
    
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
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct RecordingRowView: View {
    @EnvironmentObject var topicStore: TopicStore
    let recording: Recording
    let topicId: UUID
    
    @State private var showingTranscript = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(recording.title)
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        Label(recording.formattedDuration, systemImage: "clock")
                        Label(recording.formattedDate, systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                TranscriptionStatusBadge(status: recording.transcriptionStatus) {
                    if recording.transcriptionStatus == .failed {
                        topicStore.retryTranscription(for: recording, in: topicId)
                    }
                }
            }
            
            if let transcript = recording.transcript, !transcript.isEmpty {
                Button {
                    showingTranscript = true
                } label: {
                    Text(transcript)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingTranscript) {
            TranscriptView(recording: recording)
        }
    }
}

struct TranscriptionStatusBadge: View {
    let status: TranscriptionStatus
    let onRetry: () -> Void
    
    var body: some View {
        Button(action: onRetry) {
            HStack(spacing: 4) {
                if status == .inProgress {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: status.iconName)
                }
                Text(status.rawValue)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor, in: Capsule())
            .foregroundStyle(foregroundColor)
        }
        .buttonStyle(.plain)
        .disabled(status != .failed)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return Color.orange.opacity(0.2)
        case .inProgress: return Color.blue.opacity(0.2)
        case .completed: return Color.green.opacity(0.2)
        case .failed: return Color.red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    NavigationStack {
        TopicDetailView(topic: Topic(name: "Sample Topic", description: "A test topic"))
    }
    .environmentObject(TopicStore())
}
