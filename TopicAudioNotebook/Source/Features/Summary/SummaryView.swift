import SwiftUI

struct SummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SummaryViewModel
    
    init(topicId: UUID, repository: TopicRepository) {
        _viewModel = State(wrappedValue: SummaryViewModel(
            topicId: topicId,
            repository: repository
        ))
    }
    
    var body: some View {
        content
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task { await viewModel.onAppear() }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var content: some View {
        if let topic = viewModel.topic {
            SummaryContentView(
                topic: topic,
                viewModel: viewModel
            )
        } else {
            ContentUnavailableView("Topic Not Found", systemImage: "questionmark.circle")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.hasSummary {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: viewModel.shareContent) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

// MARK: - Summary Content View

private struct SummaryContentView: View {
    let topic: Topic
    @Bindable var viewModel: SummaryViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TopicStatsHeader(
                    recordingsCount: topic.recordings.count,
                    notesCount: topic.notes.count
                )
                
                DisplayModePicker(selection: $viewModel.displayMode)
                
                Divider()
                
                summaryContent
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var summaryContent: some View {
        switch viewModel.displayMode {
        case .points:
            KeyPointsSection(
                points: topic.consolidatedPoints,
                isGenerating: viewModel.isGeneratingKeyPoints,
                onGenerate: { Task { await viewModel.generateKeyPoints() } }
            )
        case .longForm:
            LongFormSection(
                summary: topic.consolidatedSummary,
                isGenerating: viewModel.isGeneratingSummary,
                onGenerate: { Task { await viewModel.generateFullSummary() } }
            )
        case .fullContent:
            FullContentSection(topic: topic)
        }
    }
}

// MARK: - Preview

#Preview {
    let repository = TopicRepository()
    let topic = Topic(
        name: "Sample Topic",
        recordings: [
            Recording(
                title: "Meeting Notes",
                fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
                duration: 125,
                transcript: "This is a sample transcription of the meeting.",
                transcriptionStatus: .completed
            )
        ],
        notes: [
            Note(content: "Important follow-up items from the discussion.")
        ],
        consolidatedSummary: """
        # Executive Summary
        
        This is a consolidated summary of multiple recordings about the topic.
        
        ## Key Themes
        
        - First important point
        - Second important point
        - Third important point
        
        ## Main Points
        
        ### Theme 1
        
        Details about the first theme discussed across recordings.
        
        ### Theme 2
        
        Details about the second theme.
        
        ---
        
        *Generated from 3 recordings*
        """,
        consolidatedPoints: ["First key point", "Second key point", "Third key point"]
    )
    return SummaryView(topicId: topic.id, repository: repository)
}
