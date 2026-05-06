import SwiftUI

struct RecordingDetailView: View {
    @StateObject var viewModel: RecordingDetailViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AudioPlayerSection(audioPlayer: viewModel.audioPlayer)
                
                contentPicker
                
                if viewModel.selectedTab == 0 {
                    TranscriptSection(
                        transcript: viewModel.recording.transcript,
                        status: viewModel.recording.transcriptionStatus
                    )
                } else {
                    RecordingSummarySection(
                        summary: viewModel.recording.summary,
                        points: viewModel.recording.summaryPoints,
                        summaryStatus: viewModel.recording.summaryStatus,
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
        .onAppear(perform: viewModel.onAppear)
        .onDisappear(perform: viewModel.onDisappear)
    }
    
    // MARK: - Content Picker
    
    private var contentPicker: some View {
        Picker("Content", selection: $viewModel.selectedTab) {
            Text("Transcript").tag(0)
            Text("Summary").tag(1)
        }
        .pickerStyle(.segmented)
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
