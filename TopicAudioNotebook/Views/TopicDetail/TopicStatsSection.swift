import SwiftUI

struct TopicStatsSection: View {
    let recordingsCount: Int
    let transcribedCount: Int
    let formattedDuration: String
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Recordings",
                value: "\(recordingsCount)",
                icon: "waveform",
                color: .blue
            )
            
            StatCard(
                title: "Transcribed",
                value: "\(transcribedCount)",
                icon: "doc.text",
                color: .green
            )
            
            StatCard(
                title: "Duration",
                value: formattedDuration,
                icon: "clock",
                color: .orange
            )
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
    }
}

#Preview {
    List {
        Section {
            TopicStatsSection(
                recordingsCount: 5,
                transcribedCount: 3,
                formattedDuration: "12:30"
            )
        }
    }
}
