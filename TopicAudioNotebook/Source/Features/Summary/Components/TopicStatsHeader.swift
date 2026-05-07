import SwiftUI

struct TopicStatsHeader: View {
    let recordingsCount: Int
    let notesCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Label("\(recordingsCount)", systemImage: "waveform")
            Label("\(notesCount)", systemImage: "doc.text")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    TopicStatsHeader(recordingsCount: 5, notesCount: 3)
        .padding()
}
