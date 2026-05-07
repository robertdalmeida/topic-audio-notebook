import SwiftUI

struct TopicSummarySection: View {
    let summary: String?
    let points: [String]?
    let hasContent: Bool
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
                    points: points
                )
            } else if hasContent {
                GenerateSummaryView(onGenerate: onGenerate)
            } else {
                NoContentView()
            }
        }
    }
}

// MARK: - Summary Content View

private struct SummaryContentView: View {
    let points: [String]?
    let maxPointsToShow = 10

    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let points = points, !points.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Key Points")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    KeyPointsView(points: points, maxPoints: isExpanded ? nil : maxPointsToShow)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if (points?.count ?? 0) > maxPointsToShow {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Text(isExpanded ? "Show Less" : "Show More")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Generate Summary View

private struct GenerateSummaryView: View {
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            SummarizeButton(
                action: onGenerate
            )
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
                onGenerate: { }
            )
        }
    }
}
