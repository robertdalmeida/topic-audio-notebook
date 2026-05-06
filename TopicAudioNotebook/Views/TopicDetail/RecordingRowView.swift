import SwiftUI

struct RecordingRowView: View {
    @EnvironmentObject var topicStore: TopicStore
    
    let recording: Recording
    let topicId: UUID
    
    @State private var showingTranscript = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RecordingRowHeader(
                recording: recording,
                onRetry: {
                    if recording.transcriptionStatus == .failed {
                        topicStore.retryTranscription(for: recording, in: topicId)
                    }
                }
            )
            
            if let transcript = recording.transcript, !transcript.isEmpty {
                TranscriptPreviewButton(transcript: transcript) {
                    showingTranscript = true
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingTranscript) {
            TranscriptView(recording: recording)
        }
    }
}

// MARK: - Recording Row Header

private struct RecordingRowHeader: View {
    let recording: Recording
    let onRetry: () -> Void
    
    var body: some View {
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
            
            TranscriptionStatusBadge(
                status: recording.transcriptionStatus,
                onRetry: onRetry
            )
        }
    }
}

// MARK: - Transcript Preview Button

private struct TranscriptPreviewButton: View {
    let transcript: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
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

#Preview {
    List {
        RecordingRowView(
            recording: Recording(
                title: "Sample Recording",
                fileURL: URL(fileURLWithPath: "/test"),
                duration: 125,
                transcript: "This is a sample transcript preview that shows the first few lines.",
                transcriptionStatus: .completed
            ),
            topicId: UUID()
        )
    }
    .environmentObject(TopicStore())
}
