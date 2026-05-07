import SwiftUI

struct ContentItemView: View {
    let item: ContentItem
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: item.date)
    }
    
    private var formattedDuration: String? {
        guard let duration = item.duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ContentItemHeader(
                type: item.type,
                title: item.title,
                date: formattedDate,
                duration: formattedDuration
            )
            
            ContentItemBody(
                type: item.type,
                content: item.content
            )
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Header

private struct ContentItemHeader: View {
    let type: ContentItemType
    let title: String?
    let date: String
    let duration: String?
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: type == .recording ? "waveform" : "doc.text")
                .foregroundStyle(type == .recording ? .blue : .orange)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(itemTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                ContentItemMetadata(date: date, duration: duration)
            }
            
            Spacer()
        }
    }
    
    private var itemTitle: String {
        if type == .recording {
            return title ?? "Untitled Recording"
        } else {
            return "Note"
        }
    }
}

// MARK: - Metadata

private struct ContentItemMetadata: View {
    let date: String
    let duration: String?
    
    var body: some View {
        HStack(spacing: 8) {
            Text(date)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            if let duration {
                Text("•")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(duration)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Body

private struct ContentItemBody: View {
    let type: ContentItemType
    let content: String?
    
    var body: some View {
        if let content, !content.isEmpty {
            Text(content)
                .font(.body)
                .foregroundStyle(.primary)
                .padding(.leading, 28)
        } else if type == .recording {
            Text("No transcription available")
                .font(.body)
                .foregroundStyle(.secondary)
                .italic()
                .padding(.leading, 28)
        }
    }
}

// MARK: - Previews

#Preview("Recording with Transcript") {
    ContentItemView(
        item: ContentItem(
            id: UUID(),
            type: .recording,
            title: "Meeting Notes",
            content: "This is the transcription of the recording discussing important project updates and next steps for the team.",
            date: Date(),
            duration: 125
        )
    )
    .padding()
}

#Preview("Recording without Transcript") {
    ContentItemView(
        item: ContentItem(
            id: UUID(),
            type: .recording,
            title: "Quick Voice Memo",
            content: nil,
            date: Date(),
            duration: 45
        )
    )
    .padding()
}

#Preview("Note") {
    ContentItemView(
        item: ContentItem(
            id: UUID(),
            type: .note,
            title: nil,
            content: "Remember to follow up on the action items from today's discussion. Also need to schedule the next review meeting.",
            date: Date(),
            duration: nil
        )
    )
    .padding()
}
