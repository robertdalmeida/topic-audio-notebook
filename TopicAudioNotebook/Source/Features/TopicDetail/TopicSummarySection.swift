import SwiftUI

struct TopicSummarySection: View {
    let summary: String?
    let points: [String]?
    let hasContent: Bool
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    private var hasSummary: Bool {
        if let summary = summary, !summary.isEmpty { return true }
        if let points = points, !points.isEmpty { return true }
        return false
    }
    
    var body: some View {
        Group {
            if hasSummary {
                SummaryContentView(
                    summary: summary ?? "",
                    points: points,
                    isGenerating: isGenerating
                )
            } else if hasContent {
                GenerateSummaryView(isGenerating: isGenerating, onGenerate: onGenerate)
            } else {
                NoContentView()
            }
        }
    }
}

// MARK: - Summary Content View

private struct SummaryContentView: View {
    let summary: String
    let points: [String]?
    let isGenerating: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isGenerating {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Updating summary...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let points = points, !points.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key Points")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    KeyPointsView(points: points, maxPoints: 5)
                }
            }
            
            if !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Generate Summary View

private struct GenerateSummaryView: View {
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            if isGenerating {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Generating summary...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button(action: onGenerate) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Generate Topic Summary")
                    }
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 8))
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - No Content View

private struct NoContentView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.text")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("No content available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Add notes or recordings to generate a summary")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }
}

#Preview("With Summary") {
    List {
        Section {
            TopicSummarySection(
                summary: "This is a sample summary of the topic covering multiple recordings.",
                points: ["First point", "Second point", "Third point"],
                hasContent: true,
                isGenerating: false,
                onGenerate: { }
            )
        }
    }
}

#Preview("Updating Summary") {
    List {
        Section {
            TopicSummarySection(
                summary: "This is a sample summary of the topic covering multiple recordings.",
                points: ["First point", "Second point", "Third point"],
                hasContent: true,
                isGenerating: true,
                onGenerate: { }
            )
        }
    }
}

#Preview("Generate Button") {
    List {
        Section {
            TopicSummarySection(
                summary: nil,
                points: nil,
                hasContent: true,
                isGenerating: false,
                onGenerate: { }
            )
        }
    }
}

#Preview("No Content") {
    List {
        Section {
            TopicSummarySection(
                summary: nil,
                points: nil,
                hasContent: false,
                isGenerating: false,
                onGenerate: { }
            )
        }
    }
}
