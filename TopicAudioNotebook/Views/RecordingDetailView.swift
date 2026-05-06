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
                audioPlayerSection
                
                Picker("Content", selection: $selectedTab) {
                    Text("Transcript").tag(0)
                    Text("Summary").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if selectedTab == 0 {
                    transcriptSection
                } else {
                    summarySection
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
    
    // MARK: - Audio Player Section
    
    private var audioPlayerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: audioPlayer.progress)
                    .stroke(Color.blue, lineWidth: 4)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.1), value: audioPlayer.progress)
                
                Image(systemName: audioPlayer.isPlaying ? "waveform" : "waveform")
                    .font(.system(size: 40))
                    .foregroundStyle(.blue)
            }
            
            HStack {
                Text(audioPlayer.formattedCurrentTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                
                Slider(value: Binding(
                    get: { audioPlayer.progress },
                    set: { audioPlayer.seekToProgress($0) }
                ))
                .tint(.blue)
                
                Text(audioPlayer.formattedDuration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal)
            
            HStack(spacing: 32) {
                Button {
                    audioPlayer.skipBackward()
                } label: {
                    Image(systemName: "gobackward.15")
                        .font(.title2)
                }
                
                Button {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                } label: {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 56))
                }
                
                Button {
                    audioPlayer.skipForward()
                } label: {
                    Image(systemName: "goforward.15")
                        .font(.title2)
                }
            }
            
            HStack(spacing: 12) {
                ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { rate in
                    Button {
                        audioPlayer.setPlaybackRate(Float(rate))
                    } label: {
                        Text("\(rate, specifier: rate == 1.0 || rate == 2.0 ? "%.0f" : "%.1f")x")
                            .font(.caption)
                            .fontWeight(audioPlayer.playbackRate == Float(rate) ? .bold : .regular)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                audioPlayer.playbackRate == Float(rate) 
                                    ? Color.blue.opacity(0.2) 
                                    : Color(.systemGray6),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Transcript Section
    
    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Transcript", systemImage: "doc.text")
                    .font(.headline)
                
                Spacer()
                
                StatusBadge(
                    status: currentRecording.transcriptionStatus.rawValue,
                    icon: currentRecording.transcriptionStatus.iconName,
                    color: statusColor(for: currentRecording.transcriptionStatus)
                )
            }
            
            if let transcript = currentRecording.transcript, !transcript.isEmpty {
                Text(transcript)
                    .font(.body)
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            } else {
                ContentUnavailableView {
                    Label("No Transcript", systemImage: "doc.text")
                } description: {
                    Text(transcriptUnavailableMessage)
                }
                .frame(minHeight: 200)
            }
        }
        .padding(.horizontal)
    }
    
    private var transcriptUnavailableMessage: String {
        switch currentRecording.transcriptionStatus {
        case .pending: return "Transcription is pending..."
        case .inProgress: return "Transcribing audio..."
        case .failed: return "Transcription failed. Tap to retry."
        case .completed: return "No transcript available."
        }
    }
    
    // MARK: - Summary Section
    
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("AI Summary", systemImage: "brain")
                    .font(.headline)
                
                Spacer()
                
                if currentRecording.summaryStatus == .completed {
                    StatusBadge(status: "Ready", icon: "checkmark.circle.fill", color: .green)
                } else if isGeneratingSummary {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Button {
                        generateSummary()
                    } label: {
                        Label("Generate", systemImage: "sparkles")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .disabled(currentRecording.transcript == nil)
                }
            }
            
            if let points = currentRecording.summaryPoints, !points.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Key Points")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    ForEach(points, id: \.self) { point in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundStyle(.blue)
                                .padding(.top, 6)
                            
                            Text(point)
                                .font(.body)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            }
            
            if let summary = currentRecording.summary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Full Summary")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Text(summary)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            }
            
            if currentRecording.summary == nil && currentRecording.summaryPoints == nil && !isGeneratingSummary {
                ContentUnavailableView {
                    Label("No Summary", systemImage: "brain")
                } description: {
                    if currentRecording.transcript == nil {
                        Text("Transcript required before generating summary")
                    } else {
                        Text("Tap Generate to create an AI summary")
                    }
                }
                .frame(minHeight: 200)
            }
        }
        .padding(.horizontal)
    }
    
    private func generateSummary() {
        isGeneratingSummary = true
        Task {
            await topicStore.generateRecordingSummary(recordingId: recording.id, in: topicId)
            isGeneratingSummary = false
        }
    }
    
    private func statusColor(for status: TranscriptionStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

struct StatusBadge: View {
    let status: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(status)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2), in: Capsule())
        .foregroundStyle(color)
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
