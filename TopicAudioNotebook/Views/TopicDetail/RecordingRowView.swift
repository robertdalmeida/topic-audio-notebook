import SwiftUI

struct RecordingRowView: View {
    @StateObject var viewModel: RecordingRowViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RecordingRowHeader(
                recording: viewModel.recording,
                onRetry: viewModel.retryTranscription
            )
            
            if viewModel.hasTranscript {
                TranscriptPreviewButton(transcript: viewModel.recording.transcript!) {
                    viewModel.presentTranscript()
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $viewModel.showingTranscript) {
            TranscriptView(recording: viewModel.recording)
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
    let repository = TopicRepository()
    return List {
        RecordingRowView(
            viewModel: RecordingRowViewModel(
                recordingId: UUID(),
                topicId: UUID(),
                repository: repository
            )
        )
    }
    .environmentObject(repository)
}
