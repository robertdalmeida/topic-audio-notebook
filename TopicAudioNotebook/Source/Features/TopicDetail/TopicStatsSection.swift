import SwiftUI

struct TopicStatsSection: View {
    let recordingsCount: Int
    let notesCount: Int
    let transcribedCount: Int
    let formattedDuration: String
    
    var body: some View {
        HStack(spacing: 24) {
            Label {
                Text("\(recordingsCount)") + Text(" (\(formattedDuration))").foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "waveform")
                    .foregroundStyle(.blue)
            }
            
            Label {
                Text("\(notesCount)")
            } icon: {
                Image(systemName: "doc.text")
                    .foregroundStyle(.orange)
            }
            
            Label {
                Text("\(transcribedCount)")
            } icon: {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.green)
            }
        }
        .font(.subheadline)
        .padding(.vertical, 4)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

#Preview {
    List {
        Section {
            TopicStatsSection(
                recordingsCount: 5,
                notesCount: 3,
                transcribedCount: 3,
                formattedDuration: "12:30"
            )
        }
    }
}
