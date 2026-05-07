import SwiftUI

struct RecordingDetailView: View {
    @StateObject var viewModel: RecordingDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AudioPlayerSection(audioPlayer: viewModel.audioPlayer)
                
                contentPicker
                
                switch viewModel.selectedTab {
                case .transcript:
                    TranscriptSection(
                        transcript: viewModel.recording.transcript,
                        status: viewModel.recording.transcriptionStatus,
                        isTranscribing: viewModel.isTranscribing,
                        onRetranscribe: viewModel.retranscribe
                    )
                case .keyPoints:
                    KeyPointsTabSection(
                        points: viewModel.recording.summaryPoints,
                        hasTranscript: viewModel.hasTranscript,
                        isGenerating: viewModel.isGeneratingKeyPoints,
                        onGenerate: viewModel.generateKeyPoints
                    )
                case .summary:
                    SummaryTabSection(
                        summary: viewModel.recording.summary,
                        hasTranscript: viewModel.hasTranscript,
                        isGenerating: viewModel.isGeneratingSummary,
                        onGenerate: viewModel.generateSummary
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(viewModel.recording.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: viewModel.recording.fileURL) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
    
    // MARK: - Content Picker
    
    private var contentPicker: some View {
        Picker("Content", selection: $viewModel.selectedTab) {
            ForEach(RecordingTab.allCases, id: \.self) { tab in
                Text(tab.title).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
}

// MARK: - Key Points Tab Section

private struct KeyPointsTabSection: View {
    let points: [String]?
    let hasTranscript: Bool
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Key Points", systemImage: "list.bullet")
                    .font(.headline)
                
                Spacer()
                
                if isGenerating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    SummarizeButton(
                        isEnabled: hasTranscript,
                        action: onGenerate
                    )
                }
            }
            
            if let points = points, !points.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(points, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .font(.body)
                                .foregroundStyle(.blue)
                            
                            Text(point)
                                .font(.body)
                        }
                    }
                }
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            } else if !isGenerating {
                ContentUnavailableView {
                    Label("No Key Points", systemImage: "list.bullet")
                } description: {
                    if hasTranscript {
                        Text("Tap Generate to extract key points")
                    } else {
                        Text("Transcript required before generating key points")
                    }
                }
                .frame(minHeight: 200)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Summary Tab Section

private struct SummaryTabSection: View {
    let summary: String?
    let hasTranscript: Bool
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Summary", systemImage: "doc.text")
                    .font(.headline)
                
                Spacer()
                
                if isGenerating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    SummarizeButton(
                        isEnabled: hasTranscript,
                        action: onGenerate
                    )
                }
            }
            
            if let summary = summary, !summary.isEmpty {
                Text(summary)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            } else if !isGenerating {
                ContentUnavailableView {
                    Label("No Summary", systemImage: "doc.text")
                } description: {
                    if hasTranscript {
                        Text("Tap Generate to create a summary")
                    } else {
                        Text("Transcript required before generating summary")
                    }
                }
                .frame(minHeight: 200)
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    let repository = TopicRepository()
    return NavigationStack {
        RecordingDetailView(
            viewModel: RecordingDetailViewModel(
                recordingId: UUID(),
                topicId: UUID(),
                repository: repository
            )
        )
    }
    .environmentObject(repository)
}
