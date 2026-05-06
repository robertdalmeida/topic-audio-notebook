import SwiftUI

struct TopicDetailView: View {
    @EnvironmentObject var repository: TopicRepository
    @StateObject var viewModel: TopicDetailViewModel
    
    var body: some View {
        List {
            actionButtonsSection
            descriptionSection
            statsSection
            summarySection
            notesSection
            recordingsSection
            archivedSection
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.topic.name)
        .toolbar { topToolbar }
        .sheet(isPresented: $viewModel.showingSummary) {
            SummaryView(topic: viewModel.topic)
        }
        .sheet(isPresented: $viewModel.showingNoteEditor) {
            NoteEditorView(note: viewModel.editingNote) { content in
                viewModel.saveNote(content: content)
            }
        }
        .fullScreenCover(isPresented: $viewModel.showingRecordingSession) {
            RecordingSessionView(topicId: viewModel.topic.id, topicName: viewModel.topic.name)
        }
        .sheet(isPresented: $viewModel.showingArchivedItems) {
            ArchivedItemsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Sections
    
    private var actionButtonsSection: some View {
        Section {
            HStack(spacing: 16) {
                Button(action: viewModel.presentRecordingSession) {
                    HStack(spacing: 8) {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                        Text("Record")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                
                Button(action: viewModel.presentAddNote) {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text.badge.plus")
                            .font(.title3)
                        Text("Add Note")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.orange)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
    }
    
    @ViewBuilder
    private var descriptionSection: some View {
        if !viewModel.topic.description.isEmpty {
            Section {
                Text(viewModel.topic.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var statsSection: some View {
        Section {
            TopicStatsSection(
                recordingsCount: viewModel.topic.activeRecordings.count,
                transcribedCount: viewModel.topic.transcribedRecordingsCount,
                formattedDuration: viewModel.formattedTotalDuration
            )
        }
    }
    
    private var summarySection: some View {
        Section {
            TopicSummarySection(
                summary: viewModel.topic.consolidatedSummary,
                points: viewModel.topic.consolidatedPoints,
                hasContent: viewModel.topic.hasContentForSummary,
                isGenerating: viewModel.isGeneratingTopicSummary || viewModel.isConsolidating,
                onGenerate: viewModel.generateTopicSummary
            )
        } header: {
            HStack {
                Text("Topic Summary")
                Spacer()
                if viewModel.hasSummary {
                    Button(action: viewModel.presentSummary) {
                        Text("View Full")
                            .font(.caption)
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        Section {
            if viewModel.topic.activeNotes.isEmpty {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Tap Add Note to create one")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.topic.activeNotes) { note in
                    Button {
                        viewModel.presentEditNote(note)
                    } label: {
                        NoteRowView(note: note)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.archiveNote(note)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                }
            }
        } header: {
            HStack {
                Text("Notes")
                Spacer()
                Text("\(viewModel.topic.activeNotes.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private var recordingsSection: some View {
        Section {
            if viewModel.topic.activeRecordings.isEmpty {
                ContentUnavailableView {
                    Label("No Recordings", systemImage: "waveform")
                } description: {
                    Text("Tap Record to create one")
                }
                .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.topic.activeRecordings) { recording in
                    NavigationLink(destination: RecordingDetailView(
                        viewModel: viewModel.recordingDetailViewModel(for: recording)
                    )) {
                        RecordingRowView(viewModel: viewModel.recordingRowViewModel(for: recording))
                    }
                    .swipeActions(edge: .trailing) {
                        Button {
                            viewModel.archiveRecording(recording)
                        } label: {
                            Label("Archive", systemImage: "archivebox")
                        }
                        .tint(.orange)
                    }
                }
            }
        } header: {
            HStack {
                Text("Recordings")
                Spacer()
                Text("\(viewModel.topic.activeRecordings.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var archivedSection: some View {
        if viewModel.topic.hasArchivedItems {
            Section {
                Button(action: viewModel.presentArchivedItems) {
                    HStack {
                        Label("Archived Items", systemImage: "archivebox")
                        Spacer()
                        Text("\(viewModel.topic.archivedRecordings.count + viewModel.topic.archivedNotes.count)")
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            }
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var topToolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: viewModel.consolidate) {
                if viewModel.isConsolidating {
                    ProgressView()
                } else {
                    Label("Consolidate", systemImage: "doc.on.doc")
                }
            }
            .disabled(!viewModel.canConsolidate)
        }
    }
}

#Preview {
    let repository = TopicRepository()
    let topic = Topic(name: "Sample Topic", description: "A test topic")
    return NavigationStack {
        TopicDetailView(viewModel: TopicDetailViewModel(topicId: topic.id, repository: repository))
    }
    .environmentObject(repository)
}
