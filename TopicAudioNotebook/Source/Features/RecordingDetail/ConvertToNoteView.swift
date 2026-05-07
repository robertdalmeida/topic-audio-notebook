import SwiftUI

struct ConvertToNoteView: View {
    let recording: Recording
    let onConvert: (String) -> Void
    let onCancel: () -> Void
    
    @State private var includeTranscript = true
    @State private var includeSummary = false
    @State private var includeKeyPoints = false
    
    private var hasTranscript: Bool {
        recording.transcript != nil && !recording.transcript!.isEmpty
    }
    
    private var hasSummary: Bool {
        recording.summary != nil && !recording.summary!.isEmpty
    }
    
    private var hasKeyPoints: Bool {
        recording.summaryPoints != nil && !recording.summaryPoints!.isEmpty
    }
    
    private var notePreview: String {
        var sections: [String] = []
        
        if includeTranscript, let transcript = recording.transcript, !transcript.isEmpty {
            sections.append("## Transcript\n\n\(transcript)")
        }
        
        if includeKeyPoints, let points = recording.summaryPoints, !points.isEmpty {
            let pointsText = points.map { "• \($0)" }.joined(separator: "\n")
            sections.append("## Key Points\n\n\(pointsText)")
        }
        
        if includeSummary, let summary = recording.summary, !summary.isEmpty {
            sections.append("## Summary\n\n\(summary)")
        }
        
        if sections.isEmpty {
            return "Select at least one content type to include in the note."
        }
        
        let header = "# \(recording.title)\n\n*Converted from audio recording on \(recording.formattedDate)*\n\n"
        return header + sections.joined(separator: "\n\n---\n\n")
    }
    
    private var canConvert: Bool {
        (includeTranscript && hasTranscript) ||
        (includeSummary && hasSummary) ||
        (includeKeyPoints && hasKeyPoints)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    contentSelectionSection
                    previewSection
                }
                .padding()
            }
            .navigationTitle("Convert to Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Convert") {
                        onConvert(notePreview)
                    }
                    .fontWeight(.semibold)
                    .disabled(!canConvert)
                }
            }
        }
    }
    
    // MARK: - Content Selection Section
    
    private var contentSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Include in Note")
                .font(.headline)
            
            VStack(spacing: 12) {
                ContentToggleRow(
                    title: "Transcript",
                    subtitle: hasTranscript ? "Full transcription of the recording" : "No transcript available",
                    systemImage: "doc.text",
                    isOn: $includeTranscript,
                    isAvailable: hasTranscript
                )
                
                ContentToggleRow(
                    title: "Key Points",
                    subtitle: hasKeyPoints ? "\(recording.summaryPoints?.count ?? 0) key points extracted" : "No key points available",
                    systemImage: "list.bullet",
                    isOn: $includeKeyPoints,
                    isAvailable: hasKeyPoints
                )
                
                ContentToggleRow(
                    title: "Summary",
                    subtitle: hasSummary ? "AI-generated summary" : "No summary available",
                    systemImage: "brain",
                    isOn: $includeSummary,
                    isAvailable: hasSummary
                )
            }
            
            if !canConvert {
                Label("Select at least one available content type", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Preview Section
    
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Preview", systemImage: "eye")
                    .font(.headline)
                
                Spacer()
            }
            
            Text(notePreview)
                .font(.body)
                .textSelection(.enabled)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Content Toggle Row

private struct ContentToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(isAvailable ? .blue : .secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(isAvailable ? .primary : .secondary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .disabled(!isAvailable)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if isAvailable {
                isOn.toggle()
            }
        }
    }
}

#Preview("With All Content") {
    ConvertToNoteView(
        recording: Recording(
            title: "Meeting Notes",
            fileURL: URL(fileURLWithPath: "/test.m4a"),
            transcript: "This is a sample transcript of the meeting discussing project updates and next steps.",
            summary: "The meeting covered project progress and upcoming milestones.",
            summaryPoints: ["Project is on track", "Next milestone in 2 weeks", "Team needs additional resources"]
        ),
        onConvert: { _ in },
        onCancel: { }
    )
}

#Preview("Transcript Only") {
    ConvertToNoteView(
        recording: Recording(
            title: "Quick Note",
            fileURL: URL(fileURLWithPath: "/test.m4a"),
            transcript: "This is a sample transcript."
        ),
        onConvert: { _ in },
        onCancel: { }
    )
}
