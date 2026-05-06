import SwiftUI

struct RecordingDetailView: View {
    @EnvironmentObject var topicStore: TopicStore
    @StateObject private var audioPlayer = AudioPlayer()
    @State private var selectedTab = 0
    @State private var isGeneratingSummary = false
    
    let recording: Recording
    let topicId: UUID
    
    private var currentRecording: Recording {
        topicStore.topics
            .first { $0.id == topicId }?
            .recordings
            .first { $0.id == recording.id } ?? recording
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                AudioPlayerSection(audioPlayer: audioPlayer)
                
                contentPicker
                
                if selectedTab == 0 {
                    TranscriptSection(
                        transcript: currentRecording.transcript,
                        status: currentRecording.transcriptionStatus
                    )
                } else {
                    RecordingSummarySection(
                        summary: currentRecording.summary,
                        points: currentRecording.summaryPoints,
                        summaryStatus: currentRecording.summaryStatus,
                        hasTranscript: currentRecording.transcript != nil,
                        isGenerating: isGeneratingSummary,
                        onGenerate: generateSummary
                    )
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(currentRecording.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            audioPlayer.load(url: currentRecording.fileURL)
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }
    
    // MARK: - Content Picker
    
    private var contentPicker: some View {
        Picker("Content", selection: $selectedTab) {
            Text("Transcript").tag(0)
            Text("Summary").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    // MARK: - Actions
    
    private func generateSummary() {
        isGeneratingSummary = true
        Task {
            await topicStore.generateRecordingSummary(recordingId: recording.id, in: topicId)
            isGeneratingSummary = false
        }
    }
}

#Preview {
    NavigationStack {
        RecordingDetailView(
            recording: Recording(
                title: "Sample Recording",
                fileURL: URL(fileURLWithPath: "/test"),
                duration: 125,
                transcript: "This is a sample transcript of the recording. It contains the spoken words that were captured during the audio recording session.",
                summary: "This recording discusses the main topic with several key insights.",
                summaryPoints: ["First key point from the recording", "Second important insight", "Third notable mention"]
            ),
            topicId: UUID()
        )
    }
    .environmentObject(TopicStore())
}
