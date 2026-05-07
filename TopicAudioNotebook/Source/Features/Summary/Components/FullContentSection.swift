import SwiftUI

struct FullContentSection: View {
    let topic: Topic
    
    private var sortedItems: [ContentItem] {
        var items: [ContentItem] = []
        
        for recording in topic.activeRecordings {
            items.append(ContentItem(
                id: recording.id,
                type: .recording,
                title: recording.title,
                content: recording.transcript,
                date: recording.createdAt,
                duration: recording.duration
            ))
        }
        
        for note in topic.activeNotes {
            items.append(ContentItem(
                id: note.id,
                type: .note,
                title: nil,
                content: note.content,
                date: note.createdAt,
                duration: nil
            ))
        }
        
        return items.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FullContentHeader(
                isEmpty: sortedItems.isEmpty,
                copyText: formattedFullContent
            )
            
            FullContentList(items: sortedItems)
        }
        .textSelection(.enabled)
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
    
    var formattedFullContent: String {
        var content = "# \(topic.name) - All Content\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for item in sortedItems {
            let dateString = dateFormatter.string(from: item.date)
            
            switch item.type {
            case .recording:
                content += "## 🎙️ Recording: \(item.title ?? "Untitled")\n"
                content += "📅 \(dateString)"
                if let duration = item.duration {
                    let minutes = Int(duration) / 60
                    let seconds = Int(duration) % 60
                    content += " • ⏱️ \(String(format: "%d:%02d", minutes, seconds))"
                }
                content += "\n\n"
                if let transcript = item.content, !transcript.isEmpty {
                    content += "### Transcription\n\(transcript)\n\n"
                } else {
                    content += "*No transcription available*\n\n"
                }
            case .note:
                content += "## 📝 Note\n"
                content += "📅 \(dateString)\n\n"
                if let noteContent = item.content, !noteContent.isEmpty {
                    content += "\(noteContent)\n\n"
                }
            }
            
            content += "---\n\n"
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Header

private struct FullContentHeader: View {
    let isEmpty: Bool
    let copyText: String
    
    var body: some View {
        HStack {
            Text("All Content")
                .font(.headline)
            Spacer()
            
            if !isEmpty {
                CopyButton(text: copyText)
            }
        }
        .padding(.bottom, 4)
    }
}

// MARK: - Content List

private struct FullContentList: View {
    let items: [ContentItem]
    
    var body: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label("No Content", systemImage: "doc.text")
            } description: {
                Text("Add recordings or notes to see content here")
            }
            .frame(minHeight: 150)
        } else {
            ForEach(items) { item in
                ContentItemView(item: item)
            }
        }
    }
}

// MARK: - Models

struct ContentItem: Identifiable {
    let id: UUID
    let type: ContentItemType
    let title: String?
    let content: String?
    let date: Date
    let duration: TimeInterval?
}

enum ContentItemType {
    case recording
    case note
}

// MARK: - Previews

#Preview("With Content") {
    ScrollView {
        FullContentSection(
            topic: Topic(
                name: "Sample Topic",
                recordings: [
                    Recording(
                        title: "Meeting Notes",
                        fileURL: URL(fileURLWithPath: "/tmp/test.m4a"),
                        duration: 125,
                        transcript: "This is the transcription of the recording discussing important project updates and next steps.",
                        transcriptionStatus: .completed
                    ),
                    Recording(
                        title: "Quick Thought",
                        fileURL: URL(fileURLWithPath: "/tmp/test2.m4a"),
                        duration: 45,
                        transcriptionStatus: .pending
                    )
                ],
                notes: [
                    Note(content: "Remember to follow up on the action items from today's discussion.")
                ]
            )
        )
        .padding()
    }
}

#Preview("Empty") {
    FullContentSection(topic: Topic(name: "Empty Topic"))
        .padding()
}
