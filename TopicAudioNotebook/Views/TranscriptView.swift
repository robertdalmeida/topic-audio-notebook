import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct TranscriptView: View {
    @Environment(\.dismiss) private var dismiss
    let recording: Recording
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label(recording.formattedDuration, systemImage: "clock")
                        Spacer()
                        Label(recording.formattedDate, systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Divider()
                    
                    if let transcript = recording.transcript {
                        Text(transcript)
                            .font(.body)
                            .textSelection(.enabled)
                    } else {
                        ContentUnavailableView {
                            Label("No Transcript", systemImage: "doc.text")
                        } description: {
                            Text("Transcription is pending or failed")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(recording.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if let transcript = recording.transcript {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            copyToClipboard(transcript)
                        } label: {
                            Image(systemName: "doc.on.doc")
                        }
                    }
                    
                    ToolbarItem(placement: .secondaryAction) {
                        ShareLink(item: transcript) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
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

#Preview {
    TranscriptView(recording: Recording(
        title: "Sample Recording",
        fileURL: URL(fileURLWithPath: "/test"),
        duration: 125,
        transcript: "This is a sample transcript text that would contain the spoken words from the audio recording. It can be quite long and should be scrollable."
    ))
}
