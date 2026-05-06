import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var content: String
    
    let note: Note?
    let onSave: (String) -> Void
    
    init(note: Note? = nil, onSave: @escaping (String) -> Void) {
        self.note = note
        self.onSave = onSave
        _content = State(initialValue: note?.content ?? "")
    }
    
    private var isEditing: Bool {
        note != nil
    }
    
    private var canSave: Bool {
        !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            TextEditor(text: $content)
                .padding()
                .navigationTitle(isEditing ? "Edit Note" : "New Note")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            onSave(content)
                            dismiss()
                        }
                        .disabled(!canSave)
                    }
                }
        }
    }
}

#Preview("New Note") {
    NoteEditorView { content in
        print("Saved: \(content)")
    }
}

#Preview("Edit Note") {
    NoteEditorView(note: Note(content: "Existing note content")) { content in
        print("Updated: \(content)")
    }
}
