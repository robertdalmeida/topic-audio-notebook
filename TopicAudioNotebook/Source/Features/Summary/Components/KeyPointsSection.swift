import SwiftUI

struct KeyPointsSection: View {
    let points: [String]?
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            KeyPointsHeader(
                points: points,
                isGenerating: isGenerating,
                onGenerate: onGenerate
            )
            
            KeyPointsContent(
                points: points,
                isGenerating: isGenerating
            )
        }
        .textSelection(.enabled)
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Header

private struct KeyPointsHeader: View {
    let points: [String]?
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        HStack {
            Text("Key Points")
                .font(.headline)
            Spacer()
            
            if isGenerating {
                SummaryGeneratingIndicator()
            } else {
                HStack(spacing: 12) {
                    if let points, !points.isEmpty {
                        CopyButton(points: points)
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

private struct KeyPointsContent: View {
    let points: [String]?
    let isGenerating: Bool
    
    var body: some View {
        if let points, !points.isEmpty {
            ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                SummaryKeyPointRow(point: point)
            }
        } else if !isGenerating {
            ContentUnavailableView {
                Label("No Key Points", systemImage: "list.bullet")
            } description: {
                Text("Tap Generate to extract key points")
            }
            .frame(minHeight: 150)
        }
    }
}

// MARK: - Key Point Row

private struct SummaryKeyPointRow: View {
    let point: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .font(.body)
                .foregroundStyle(.blue)
            
            Text(point)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Previews

#Preview("With Points") {
    KeyPointsSection(
        points: ["First key point about the topic", "Second important insight", "Third conclusion"],
        isGenerating: false,
        onGenerate: {}
    )
    .padding()
}

#Preview("Empty") {
    KeyPointsSection(
        points: nil,
        isGenerating: false,
        onGenerate: {}
    )
    .padding()
}

#Preview("Generating") {
    KeyPointsSection(
        points: nil,
        isGenerating: true,
        onGenerate: {}
    )
    .padding()
}

#Preview("Key Point Row") {
    VStack {
        SummaryKeyPointRow(point: "This is a sample key point that demonstrates the row layout")
    }
    .padding()
}
