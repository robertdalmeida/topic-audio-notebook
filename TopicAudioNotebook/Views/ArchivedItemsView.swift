import SwiftUI

struct ArchivedItemsView: View {
    @ObservedObject var viewModel: TopicDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedNote: Note?
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.topic.archivedRecordings.isEmpty && viewModel.topic.archivedNotes.isEmpty {
                    emptyStateView
                } else {
                    if !viewModel.topic.archivedRecordings.isEmpty {
                        archivedRecordingsSection
                    }
                    
                    if !viewModel.topic.archivedNotes.isEmpty {
                        archivedNotesSection
                    }
                }
            }
            .navigationTitle("Archived Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(item: $selectedNote) { note in
                ArchivedNoteDetailView(note: note)
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Archived Items",
            systemImage: "archivebox",
            description: Text("Archived recordings and notes will appear here")
        )
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Archived Recordings Section
    
    private var archivedRecordingsSection: some View {
        Section("Archived Recordings") {
            ForEach(viewModel.topic.archivedRecordings) { recording in
                NavigationLink {
                    RecordingDetailView(
                        viewModel: viewModel.recordingDetailViewModel(for: recording)
                    )
                } label: {
                    ArchivedRecordingRow(
                        recording: recording,
                        onUnarchive: { viewModel.unarchiveRecording(recording) },
                        onDelete: { viewModel.deleteRecordingPermanently(recording) }
                    )
                }
            }
        }
    }
    
    // MARK: - Archived Notes Section
    
    private var archivedNotesSection: some View {
        Section("Archived Notes") {
            ForEach(viewModel.topic.archivedNotes) { note in
                Button {
                    selectedNote = note
                } label: {
                    ArchivedNoteRow(
                        note: note,
                        onUnarchive: { viewModel.unarchiveNote(note) },
                        onDelete: { viewModel.deleteNotePermanently(note) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Archived Recording Row

struct ArchivedRecordingRow: View {
    let recording: Recording
    let onUnarchive: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recording.title)
                .font(.headline)
            
            HStack(spacing: 12) {
                Label(recording.formattedDuration, systemImage: "waveform")
                Label(recording.formattedDate, systemImage: "calendar")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onUnarchive()
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
        }
        .confirmationDialog("Delete Recording?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the recording and its audio file. This action cannot be undone.")
        }
    }
}

// MARK: - Archived Note Row

struct ArchivedNoteRow: View {
    let note: Note
    let onUnarchive: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(note.preview)
                .font(.headline)
                .lineLimit(2)
            
            Text(note.formattedDate)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                onUnarchive()
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }
            .tint(.blue)
        }
        .confirmationDialog("Delete Note?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete Permanently", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the note. This action cannot be undone.")
        }
    }
}

// MARK: - Archived Note Detail View

struct ArchivedNoteDetailView: View {
    let note: Note
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("Archived", systemImage: "archivebox.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                        
                        Spacer()
                        
                        Text(note.formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(note.content)
                        .font(.body)
                        .textSelection(.enabled)
                }
                .padding()
            }
            .navigationTitle("Archived Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }
    }
    
    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = note.content
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note.content, forType: .string)
        #endif
    }
}

#Preview {
    let repository = TopicRepository()
    return ArchivedItemsView(
        viewModel: TopicDetailViewModel(topicId: UUID(), repository: repository)
    )
}
