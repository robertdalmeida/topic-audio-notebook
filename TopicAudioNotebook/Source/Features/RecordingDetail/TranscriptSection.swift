import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct TranscriptSection: View {
    let transcript: String?
    let status: TranscriptionStatus
    let isTranscribing: Bool
    let onRetranscribe: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TranscriptHeader(
                status: status,
                transcript: transcript,
                isTranscribing: isTranscribing,
                onRetranscribe: onRetranscribe
            )
            
            if let transcript = transcript, !transcript.isEmpty {
                TranscriptContent(transcript: transcript)
            } else {
                TranscriptUnavailableView(status: status)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Transcript Header

private struct TranscriptHeader: View {
    let status: TranscriptionStatus
    let transcript: String?
    let isTranscribing: Bool
    let onRetranscribe: () -> Void
    
    var body: some View {
        HStack {
            Label("Transcript", systemImage: "doc.text")
                .font(.headline)
            
            Spacer()
            
            if isTranscribing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Transcribing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 12) {
                    if let transcript = transcript, !transcript.isEmpty {
                        Button {
                            copyToClipboard(transcript)
                        } label: {
                            Image(systemName: "doc.on.doc")
                                .font(.subheadline)
                        }
                    }
                    
                    Button {
                        onRetranscribe()
                    } label: {
                        Label("Re-transcribe", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
    }

    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Transcript Content

private struct TranscriptContent: View {
    let transcript: String
    
    var body: some View {
        Text(transcript)
            .font(.body)
            .textSelection(.enabled)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Transcript Unavailable View

private struct TranscriptUnavailableView: View {
    let status: TranscriptionStatus
    
    private var message: String {
        switch status {
        case .pending: return "Transcription is pending..."
        case .inProgress: return "Transcribing audio..."
        case .failed: return "Transcription failed. Tap to retry."
        case .completed: return "No transcript available."
        }
    }
    
    var body: some View {
        ContentUnavailableView {
            Label("No Transcript", systemImage: "doc.text")
        } description: {
            Text(message)
        }
        .frame(minHeight: 200)
    }
}

#Preview("With Transcript") {
    ScrollView {
        TranscriptSection(
            transcript: "This is a sample transcript of the recording. It contains the spoken words that were captured during the audio recording session.",
            status: .completed,
            isTranscribing: false,
            onRetranscribe: {}
        )
    }
}

#Preview("No Transcript") {
    ScrollView {
        TranscriptSection(
            transcript: nil,
            status: .pending,
            isTranscribing: false,
            onRetranscribe: {}
        )
    }
}

#Preview("Transcribing") {
    ScrollView {
        TranscriptSection(
            transcript: "Previous transcript...",
            status: .inProgress,
            isTranscribing: true,
            onRetranscribe: {}
        )
    }
}
