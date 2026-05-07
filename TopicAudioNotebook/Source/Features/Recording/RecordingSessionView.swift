import SwiftUI
import Speech

struct RecordingSessionView: View {
    @EnvironmentObject var repository: TopicRepository
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = AudioRecorder()
    @State private var liveTranscriber: (any LiveTranscriptionServiceProtocol)?
    
    let topicId: UUID
    let topicName: String
    
    @State private var currentFileURL: URL?
    @State private var showingDiscardAlert = false
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                headerSection
                
                visualizerSection
                    .padding(.top, 20)
                
                timerSection
                
                liveTranscriptionSection
                
                Spacer()
                
                controlsSection
                
                Spacer()
                    .frame(height: 20)
            }
            .padding()
            .background(Color(.systemBackground))
            .navigationTitle("Recording")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert("Discard Recording?", isPresented: $showingDiscardAlert) {
                Button("Discard", role: .destructive) { discardRecording() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This recording will be permanently deleted.")
            }
            .alert("Error", isPresented: .constant(recorder.errorMessage != nil)) {
                Button("OK") { recorder.errorMessage = nil }
            } message: {
                Text(recorder.errorMessage ?? "")
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(topicName)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                Text(statusText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.top, 20)
    }
    
    private var statusColor: Color {
        switch recorder.state {
        case .idle: return .gray
        case .recording: return .red
        case .paused: return .orange
        }
    }
    
    private var statusText: String {
        switch recorder.state {
        case .idle: return "Ready to Record"
        case .recording: return "Recording..."
        case .paused: return "Paused"
        }
    }
    
    // MARK: - Visualizer Section
    
    private var visualizerSection: some View {
        AudioVisualizerView(level: recorder.audioLevel, isRecording: recorder.isRecording)
            .frame(height: 120)
            .padding(.horizontal)
    }
    
    // MARK: - Timer Section
    
    private var timerSection: some View {
        VStack(spacing: 4) {
            Text(recorder.formattedTime)
                .font(.system(size: 56, weight: .thin, design: .monospaced))
                .foregroundStyle(recorder.hasActiveSession ? .primary : .secondary)
            
            if recorder.hasActiveSession {
                Text("Tap pause to take a break")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 12)
    }
    
    // MARK: - Live Transcription Section
    
    private var liveTranscriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Live Transcription", systemImage: "text.bubble")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                if liveTranscriber?.isTranscribing == true {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            
            ScrollView {
                Text((liveTranscriber?.transcript.isEmpty ?? true) ? "Start recording to see live transcription..." : (liveTranscriber?.transcript ?? ""))
                    .font(.body)
                    .foregroundStyle((liveTranscriber?.transcript.isEmpty ?? true) ? .tertiary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 100)
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal)
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: 24) {
            mainControls
            
            if recorder.hasActiveSession {
                secondaryControls
            }
        }
    }
    
    private var mainControls: some View {
        HStack(spacing: 40) {
            if recorder.hasActiveSession {
                Button(action: { showingDiscardAlert = true }) {
                    VStack(spacing: 6) {
                        Image(systemName: "trash.fill")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(Color.red.opacity(0.15))
                            .foregroundStyle(.red)
                            .clipShape(Circle())
                        
                        Text("Discard")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Button(action: handleMainButtonTap) {
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(mainButtonColor)
                            .frame(width: 80, height: 80)
                        
                        mainButtonIcon
                            .font(.title)
                            .foregroundStyle(.white)
                    }
                    
                    Text(mainButtonLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if recorder.hasActiveSession {
                Button(action: finishRecording) {
                    VStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.title2)
                            .frame(width: 56, height: 56)
                            .background(Color.green.opacity(0.15))
                            .foregroundStyle(.green)
                            .clipShape(Circle())
                        
                        Text("Done")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private var mainButtonColor: Color {
        switch recorder.state {
        case .idle: return .blue
        case .recording: return .orange
        case .paused: return .blue
        }
    }
    
    @ViewBuilder
    private var mainButtonIcon: some View {
        switch recorder.state {
        case .idle:
            Image(systemName: "mic.fill")
        case .recording:
            Image(systemName: "pause.fill")
        case .paused:
            Image(systemName: "mic.fill")
        }
    }
    
    private var mainButtonLabel: String {
        switch recorder.state {
        case .idle: return "Record"
        case .recording: return "Pause"
        case .paused: return "Resume"
        }
    }
    
    private var secondaryControls: some View {
        HStack(spacing: 32) {
            Label("\(recorder.formattedTime)", systemImage: "waveform")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if recorder.hasActiveSession {
                    showingDiscardAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func handleMainButtonTap() {
        switch recorder.state {
        case .idle:
            startRecording()
        case .recording:
            recorder.pauseRecording()
        case .paused:
            recorder.resumeRecording()
        }
    }
    
    private func startRecording() {
        Task {
            let directory = repository.getRecordingsDirectory()
            currentFileURL = await recorder.startRecording(to: directory)
            liveTranscriber = TranscriptionServiceFactory.shared.createLiveTranscriber()
            await liveTranscriber?.startTranscribing()
        }
    }
    
    private func finishRecording() {
        liveTranscriber?.stopTranscribing()
        guard let result = recorder.stopRecording() else { return }
        currentFileURL = result.0
        saveRecording()
    }
    
    private func saveRecording() {
        guard let url = currentFileURL else { return }
        isSaving = true
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        let title = "\(topicName) - \(formatter.string(from: Date()))"
        let duration = recorder.recordingTime
        let liveTranscript = liveTranscriber?.transcript ?? ""
        
        repository.addRecording(to: topicId, title: title, fileURL: url, duration: duration)
        
        if let topic = repository.topics.first(where: { $0.id == topicId }),
           let recording = topic.recordings.last {
            if !liveTranscript.isEmpty {
                repository.updateRecordingTranscript(recordingId: recording.id, in: topicId, transcript: liveTranscript)
            } else {
                repository.retryTranscription(for: recording, in: topicId)
            }
        }
        
        dismiss()
    }
    
    private func discardRecording() {
        recorder.cancelRecording()
        if let url = currentFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        dismiss()
    }
}

#Preview {
    RecordingSessionView(topicId: UUID(), topicName: "Sample Topic")
        .environmentObject(TopicRepository())
}
