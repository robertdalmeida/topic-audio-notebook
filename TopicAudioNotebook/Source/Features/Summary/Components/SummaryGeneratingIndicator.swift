import SwiftUI

struct SummaryGeneratingIndicator: View {
    var body: some View {
        HStack(spacing: 6) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Generating...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SummaryGeneratingIndicator()
        .padding()
}
