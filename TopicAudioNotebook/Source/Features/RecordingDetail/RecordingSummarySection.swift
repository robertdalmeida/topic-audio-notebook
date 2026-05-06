import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct RecordingSummarySection: View {
    let summary: String?
    let points: [String]?
    let summaryStatus: SummaryStatus
    let hasTranscript: Bool
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SummaryHeader(
                summaryStatus: summaryStatus,
                isGenerating: isGenerating,
                hasTranscript: hasTranscript,
                onGenerate: onGenerate
            )
            
            if let points = points, !points.isEmpty {
                SummaryKeyPointsCard(points: points)
            }
            
            if let summary = summary, !summary.isEmpty {
                SummaryTextCard(summary: summary)
            }
            
            if summary == nil && points == nil && !isGenerating {
                SummaryUnavailableView(hasTranscript: hasTranscript)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Summary Header

private struct SummaryHeader: View {
    let summaryStatus: SummaryStatus
    let isGenerating: Bool
    let hasTranscript: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        HStack {
            Label("AI Summary", systemImage: "brain")
                .font(.headline)
            
            Spacer()
            
            if summaryStatus == .completed {
                Button(action: onGenerate) {
                    Label("Generate", systemImage: "sparkles")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)

            } else if isGenerating {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(action: onGenerate) {
                    Label("Generate", systemImage: "sparkles")
                        .font(.subheadline)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .disabled(!hasTranscript)
            }
        }
    }
}

// MARK: - Summary Key Points Card

private struct SummaryKeyPointsCard: View {
    let points: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Key Points")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    copyPointsToClipboard()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            ForEach(points, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .font(.body)
                        .foregroundStyle(.blue)
                    
                    Text(point)
                        .font(.body)
                }
            }
        }
        .textSelection(.enabled)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func copyPointsToClipboard() {
        let text = points.map { "• \($0)" }.joined(separator: "\n")
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Summary Text Card

private struct SummaryTextCard: View {
    let summary: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Full Summary")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button {
                    copySummaryToClipboard()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Text(summary)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func copySummaryToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = summary
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(summary, forType: .string)
        #endif
    }
}

// MARK: - Summary Unavailable View

private struct SummaryUnavailableView: View {
    let hasTranscript: Bool
    
    var body: some View {
        ContentUnavailableView {
            Label("No Summary", systemImage: "brain")
        } description: {
            if hasTranscript {
                Text("Tap Generate to create an AI summary")
            } else {
                Text("Transcript required before generating summary")
            }
        }
        .frame(minHeight: 200)
    }
}

#Preview("With Summary") {
    ScrollView {
        RecordingSummarySection(
            summary: "This recording discusses the main topic with several key insights.",
            points: ["First key point", "Second important insight", "Third notable mention"],
            summaryStatus: .completed,
            hasTranscript: true,
            isGenerating: false,
            onGenerate: { }
        )
    }
}

#Preview("No Summary") {
    ScrollView {
        RecordingSummarySection(
            summary: nil,
            points: nil,
            summaryStatus: .notAvailable,
            hasTranscript: true,
            isGenerating: false,
            onGenerate: { }
        )
    }
}
