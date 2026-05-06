import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct TranscriptSection: View {
    let transcript: String?
    let status: TranscriptionStatus
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TranscriptHeader(status: status, transcript: transcript)
            
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
    
    var body: some View {
        HStack {
            Label("Transcript", systemImage: "doc.text")
                .font(.headline)
            
            Spacer()
            
            if let transcript = transcript, !transcript.isEmpty {
                Button {
                    copyToClipboard(transcript)
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.subheadline)
                }
            }
            
            StatusBadge(
                status: status.rawValue,
                icon: status.iconName,
                color: statusColor
            )
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
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
            status: .completed
        )
    }
}

#Preview("No Transcript") {
    ScrollView {
        TranscriptSection(
            transcript: nil,
            status: .pending
        )
    }
}
