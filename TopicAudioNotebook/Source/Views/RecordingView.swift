import SwiftUI

struct RecordingView: View {
    @EnvironmentObject var repository: TopicRepository
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recorder = AudioRecorder()
    
    let topicId: UUID
    
    @State private var recordingTitle = ""
    @State private var currentFileURL: URL?
    @State private var showingSaveDialog = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                AudioVisualizerView(level: recorder.audioLevel, isRecording: recorder.isRecording)
                
                Text(recorder.formattedTime)
                    .font(.system(size: 64, weight: .light, design: .monospaced))
                    .foregroundStyle(recorder.isRecording ? .primary : .secondary)
                
                Spacer()
                
                HStack(spacing: 60) {
                    if recorder.isRecording {
                        Button {
                            recorder.cancelRecording()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Button {
                        if recorder.isRecording {
                            stopRecording()
                        } else {
                            startRecording()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(recorder.isRecording ? .red : .blue)
                                .frame(width: 80, height: 80)
                            
                            if recorder.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(.white)
                                    .frame(width: 28, height: 28)
                            } else {
                                Circle()
                                    .fill(.white)
                                    .frame(width: 28, height: 28)
                            }
                        }
                    }
                    
                    if recorder.isRecording {
                        Color.clear
                            .frame(width: 56, height: 56)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Record")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        recorder.cancelRecording()
                        dismiss()
                    }
                }
            }
            .alert("Save Recording", isPresented: $showingSaveDialog) {
                TextField("Recording Title", text: $recordingTitle)
                Button("Save") {
                    saveRecording()
                }
                Button("Discard", role: .destructive) {
                    discardRecording()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Enter a title for this recording")
            }
            .alert("Error", isPresented: .constant(recorder.errorMessage != nil)) {
                Button("OK") {
                    recorder.errorMessage = nil
                }
            } message: {
                Text(recorder.errorMessage ?? "")
            }
        }
    }
    
    private func startRecording() {
        Task {
            let directory = repository.getRecordingsDirectory()
            currentFileURL = await recorder.startRecording(to: directory)
        }
    }
    
    private func stopRecording() {
        guard let result = recorder.stopRecording() else { return }
        currentFileURL = result.0
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        recordingTitle = "Recording - \(formatter.string(from: Date()))"
        
        showingSaveDialog = true
    }
    
    private func saveRecording() {
        guard let url = currentFileURL,
              let result = recorder.stopRecording() ?? (currentFileURL.map { ($0, recorder.recordingTime) }) else {
            return
        }
        
        let title = recordingTitle.isEmpty ? "Untitled Recording" : recordingTitle
        repository.addRecording(to: topicId, title: title, fileURL: url, duration: result.1)
        dismiss()
    }
    
    private func discardRecording() {
        if let url = currentFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        dismiss()
    }
}

struct AudioVisualizerView: View {
    let level: Float
    let isRecording: Bool
    
    private let barCount = 40
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                AudioBar(
                    height: barHeight(for: index),
                    isActive: isRecording
                )
            }
        }
        .frame(height: 100)
    }
    
    private func barHeight(for index: Int) -> CGFloat {
        guard isRecording else { return 4 }
        
        let center = barCount / 2
        let distance = abs(index - center)
        let normalizedDistance = CGFloat(distance) / CGFloat(center)
        
        let baseHeight = CGFloat(level) * 100
        let variation = sin(Double(index) * 0.5 + Date().timeIntervalSince1970 * 10) * 20
        let height = baseHeight * (1 - normalizedDistance * 0.5) + CGFloat(variation) * CGFloat(level)
        
        return max(4, min(100, height))
    }
}

struct AudioBar: View {
    let height: CGFloat
    let isActive: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(isActive ? Color.blue : Color.gray.opacity(0.3))
            .frame(width: 4, height: height)
            .animation(.easeInOut(duration: 0.1), value: height)
    }
}

#Preview {
    RecordingView(topicId: UUID())
        .environmentObject(TopicRepository())
}
