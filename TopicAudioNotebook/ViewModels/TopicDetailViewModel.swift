import Foundation
import Combine

@MainActor
final class TopicDetailViewModel: ObservableObject {
    @Published private(set) var topic: Topic
    @Published private(set) var isRecording = false
    @Published private(set) var isConsolidating = false
    @Published private(set) var isGeneratingTopicSummary = false
    @Published var showingSummary = false
    @Published var showingNoteEditor = false
    @Published var editingNote: Note?
    @Published private(set) var recordingTime: String = "00:00"
    
    private let topicId: UUID
    private let repository: TopicRepository
    private let recorder: AudioRecorder
    private var currentRecordingURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    var formattedTotalDuration: String {
        let total = topic.totalDuration
        let minutes = Int(total) / 60
        let seconds = Int(total) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var canConsolidate: Bool {
        topic.hasContentForSummary && !isConsolidating
    }
    
    var hasSummary: Bool {
        topic.consolidatedSummary != nil
    }
    
    init(topicId: UUID, repository: TopicRepository, recorder: AudioRecorder? = nil) {
        self.topicId = topicId
        self.repository = repository
        self.recorder = recorder ?? AudioRecorder()
        self.topic = repository.topic(for: topicId) ?? Topic(name: "Unknown")
        setupBindings()
    }
    
    private func setupBindings() {
        repository.$topics
            .compactMap { [topicId] topics in
                topics.first { $0.id == topicId }
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$topic)
        
        recorder.$recordingTime
            .map { time in
                let minutes = Int(time) / 60
                let seconds = Int(time) % 60
                return String(format: "%02d:%02d", minutes, seconds)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: &$recordingTime)
    }
    
    // MARK: - Recording Actions
    
    func toggleRecording() {
        if isRecording {
            stopRecordingAndSave()
        } else {
            startRecording()
        }
    }
    
    private func startRecording() {
        Task {
            let directory = repository.getRecordingsDirectory()
            currentRecordingURL = await recorder.startRecording(to: directory)
            if currentRecordingURL != nil {
                isRecording = true
            }
        }
    }
    
    private func stopRecordingAndSave() {
        guard let result = recorder.stopRecording(),
              currentRecordingURL != nil else {
            isRecording = false
            return
        }
        
        let title = generateRecordingTitle()
        repository.addRecording(to: topicId, title: title, fileURL: result.0, duration: result.1)
        
        isRecording = false
        currentRecordingURL = nil
    }
    
    private func generateRecordingTitle() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        let dateStr = formatter.string(from: Date())
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let timeStr = timeFormatter.string(from: Date())
        
        let recordingNumber = topic.recordings.count + 1
        return "\(topic.name) #\(recordingNumber) - \(dateStr), \(timeStr)"
    }
    
    // MARK: - Recording Management
    
    func deleteRecording(at offsets: IndexSet) {
        for index in offsets {
            let recording = topic.recordings[index]
            repository.deleteRecording(recording, from: topicId)
        }
    }
    
    // MARK: - Summary Actions
    
    func consolidate() {
        isConsolidating = true
        Task {
            await repository.consolidateSummary(for: topicId)
            isConsolidating = false
            if repository.topic(for: topicId)?.consolidatedSummary != nil {
                showingSummary = true
            }
        }
    }
    
    func generateTopicSummary() {
        isGeneratingTopicSummary = true
        Task {
            await repository.consolidateSummary(for: topicId)
            isGeneratingTopicSummary = false
        }
    }
    
    func presentSummary() {
        showingSummary = true
    }
    
    // MARK: - Note Actions
    
    func presentAddNote() {
        editingNote = nil
        showingNoteEditor = true
    }
    
    func presentEditNote(_ note: Note) {
        editingNote = note
        showingNoteEditor = true
    }
    
    func saveNote(content: String) {
        if let existingNote = editingNote {
            var updatedNote = existingNote
            updatedNote.content = content
            repository.updateNote(updatedNote, in: topicId)
        } else {
            repository.addNote(to: topicId, content: content)
        }
        editingNote = nil
    }
    
    func deleteNote(at offsets: IndexSet) {
        for index in offsets {
            let note = topic.notes[index]
            repository.deleteNote(note, from: topicId)
        }
    }
    
    // MARK: - Child ViewModels
    
    func recordingDetailViewModel(for recording: Recording) -> RecordingDetailViewModel {
        RecordingDetailViewModel(
            recordingId: recording.id,
            topicId: topicId,
            repository: repository
        )
    }
    
    func recordingRowViewModel(for recording: Recording) -> RecordingRowViewModel {
        RecordingRowViewModel(
            recordingId: recording.id,
            topicId: topicId,
            repository: repository
        )
    }
}
