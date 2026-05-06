import SwiftUI

struct TopicDetailView: View {
    @EnvironmentObject var repository: TopicRepository
    @StateObject var viewModel: TopicDetailViewModel
    
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
        .navigationTitle(viewModel.topic.name)
        .toolbar { topToolbar }
        .sheet(isPresented: $viewModel.showingSummary) {
            SummaryView(topic: viewModel.topic)
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var descriptionSection: some View {
        if !viewModel.topic.description.isEmpty {
            Section {
                Text(viewModel.topic.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var statsSection: some View {
        Section {
            TopicStatsSection(
                recordingsCount: viewModel.topic.recordings.count,
                transcribedCount: viewModel.topic.transcribedRecordingsCount,
                formattedDuration: viewModel.formattedTotalDuration
            )
        }
    }
    
    private var summarySection: some View {
        Section {
            TopicSummarySection(
                summary: viewModel.topic.consolidatedSummary,
                points: viewModel.topic.consolidatedPoints,
                transcribedCount: viewModel.topic.transcribedRecordingsCount,
                isGenerating: viewModel.isGeneratingTopicSummary || viewModel.isConsolidating,
                onGenerate: viewModel.generateTopicSummary
            )
        } header: {
            HStack {
                Text("Topic Summary")
                Spacer()
                if viewModel.hasSummary {
                    Button(action: viewModel.presentSummary) {
                        Text("View Full")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var recordingsSection: some View {
        Section {
            if viewModel.topic.recordings.isEmpty {
                ContentUnavailableView {
                    Label("No Recordings", systemImage: "waveform")
                } description: {
                    Text("Tap the microphone button to record")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.topic.recordings) { recording in
                    NavigationLink(destination: RecordingDetailView(
                        viewModel: viewModel.recordingDetailViewModel(for: recording)
                    )) {
                        RecordingRowView(viewModel: viewModel.recordingRowViewModel(for: recording))
                    }
                }
                .onDelete(perform: viewModel.deleteRecording)
            }
        } header: {
            Text("Recordings")
        }
    }
    
    // MARK: - Record Button
    
    private var recordButton: some View {
        Button(action: viewModel.toggleRecording) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(viewModel.isRecording ? Color.red : Color.blue)
                        .frame(width: 56, height: 56)
                    
                    if viewModel.isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: "mic.fill")
                            .font(.title2)
                            .foregroundStyle(.white)
                    }
                }
                
                if viewModel.isRecording {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recording...")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(viewModel.recordingTime)
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
                    .fill(viewModel.isRecording ? Color.red.opacity(0.15) : Color.blue.opacity(0.15))
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
            Button(action: viewModel.consolidate) {
                if viewModel.isConsolidating {
                    ProgressView()
                } else {
                    Label("Consolidate", systemImage: "doc.on.doc")
                }
            }
            .disabled(!viewModel.canConsolidate)
        }
    }
}

#Preview {
    let repository = TopicRepository()
    let topic = Topic(name: "Sample Topic", description: "A test topic")
    return NavigationStack {
        TopicDetailView(viewModel: TopicDetailViewModel(topicId: topic.id, repository: repository))
    }
    .environmentObject(repository)
}
