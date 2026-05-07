import SwiftUI

struct LongFormSection: View {
    let summary: String?
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LongFormHeader(
                summary: summary,
                isGenerating: isGenerating,
                onGenerate: onGenerate
            )
            
            LongFormContent(
                summary: summary,
                isGenerating: isGenerating
            )
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Header

private struct LongFormHeader: View {
    let summary: String?
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        HStack {
            Text("Full Summary")
                .font(.headline)
            Spacer()
            
            if isGenerating {
                SummaryGeneratingIndicator()
            } else {
                HStack(spacing: 12) {
                    if let summary, !summary.isEmpty {
                        CopyButton(text: summary)
                    }
                    SummarizeButton(action: onGenerate)
                        .controlSize(.small)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Content

private struct LongFormContent: View {
    let summary: String?
    let isGenerating: Bool
    
    var body: some View {
        if let summary, !summary.isEmpty {
            MarkdownTextView(text: summary)
        } else if !isGenerating {
            ContentUnavailableView {
                Label("No Summary", systemImage: "doc.richtext")
            } description: {
                Text("Tap Generate to create a summary")
            }
            .frame(minHeight: 150)
        }
    }
}

// MARK: - Previews

#Preview("With Summary") {
    ScrollView {
        LongFormSection(
            summary: """
            # Executive Summary
            
            This is a consolidated summary of multiple recordings about the topic.
            
            ## Key Themes
            
            - First important point
            - Second important point
            - Third important point
            
            ## Main Points
            
            ### Theme 1
            
            Details about the first theme discussed across recordings.
            
            ### Theme 2
            
            Details about the second theme.
            """,
            isGenerating: false,
            onGenerate: {}
        )
        .padding()
    }
}

#Preview("Empty") {
    LongFormSection(
        summary: nil,
        isGenerating: false,
        onGenerate: {}
    )
    .padding()
}

#Preview("Generating") {
    LongFormSection(
        summary: nil,
        isGenerating: true,
        onGenerate: {}
    )
    .padding()
}
