import SwiftUI

struct KeyPointsView: View {
    let points: [String]
    var maxPoints: Int? = nil
    var showMoreIndicator: Bool = true
    
    private var displayedPoints: [String] {
        if let max = maxPoints {
            return Array(points.prefix(max))
        }
        return points
    }
    
    private var remainingCount: Int {
        guard let maxPts = maxPoints else { return 0 }
        return Swift.max(0, points.count - maxPts)
    }
    
    private var formattedText: String {
        displayedPoints.map { "• \($0)" }.joined(separator: "\n")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(displayedPoints, id: \.self) { point in
                KeyPointRow(point: point)
            }
            
            if showMoreIndicator && remainingCount > 0 {
                Text("+ \(remainingCount) more points")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .textSelection(.enabled)
    }
}

struct KeyPointRow: View {
    let point: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline)
                .foregroundStyle(.blue)
            
            Text(point)
                .font(.subheadline)
        }
    }
}

#Preview {
    KeyPointsView(
        points: [
            "First key point from the recording",
            "Second important insight",
            "Third notable mention",
            "Fourth point here",
            "Fifth point",
            "Sixth point"
        ],
        maxPoints: 5
    )
    .padding()
}
