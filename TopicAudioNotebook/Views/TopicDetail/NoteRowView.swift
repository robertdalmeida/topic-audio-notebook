import SwiftUI

struct NoteRowView: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.preview)
                .font(.body)
                .lineLimit(2)
            
            Text(note.formattedDate)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        NoteRowView(note: Note(content: "This is a sample note with some content that might be longer than expected and span multiple lines."))
        NoteRowView(note: Note(content: "Short note"))
    }
}
