import Foundation
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var apiKey = ""
    @Published var showingAPIKey = false
    @Published private(set) var hasAPIKey = false
    @Published var selectedStorageType: StorageType = .file
    @Published private(set) var isSwitchingStorage = false
    @Published var showingStorageConfirmation = false
    @Published var selectedSummarizationProvider: SummarizationProvider = .onDevice
    @Published var selectedTranscriptionProvider: TranscriptionProvider = .sfSpeechRecognizer
    
    private let repository: TopicRepository
    private let summarizationFactory: SummarizationServiceFactory
    private let transcriptionFactory: TranscriptionServiceFactory
    private var cancellables = Set<AnyCancellable>()
    
    var currentStorageType: StorageType {
        repository.currentStorageType
    }
    
    var canSaveAPIKey: Bool {
        !apiKey.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    init(
        repository: TopicRepository,
        summarizationFactory: SummarizationServiceFactory = .shared,
        transcriptionFactory: TranscriptionServiceFactory = .shared
    ) {
        self.repository = repository
        self.summarizationFactory = summarizationFactory
        self.transcriptionFactory = transcriptionFactory
        setupInitialState()
    }
    
    private func setupInitialState() {
        selectedStorageType = repository.currentStorageType
        selectedSummarizationProvider = summarizationFactory.currentProvider
        selectedTranscriptionProvider = transcriptionFactory.currentProvider
        checkAPIKey()
    }
    
    // MARK: - Storage Actions
    
    func onStorageTypeChanged(to newValue: StorageType) {
        if newValue != repository.currentStorageType {
            showingStorageConfirmation = true
        }
    }
    
    func confirmStorageSwitch() {
        switchStorage()
    }
    
    func cancelStorageSwitch() {
        selectedStorageType = repository.currentStorageType
    }
    
    private func switchStorage() {
        isSwitchingStorage = true
        Task {
            await repository.switchStorage(to: selectedStorageType)
            isSwitchingStorage = false
        }
    }
    
    // MARK: - Summarization Actions
    
    func onSummarizationProviderChanged(to newValue: SummarizationProvider) {
        summarizationFactory.setProvider(newValue)
    }
    
    // MARK: - Transcription Actions
    
    func onTranscriptionProviderChanged(to newValue: TranscriptionProvider) {
        transcriptionFactory.setProvider(newValue)
    }
    
    // MARK: - API Key Actions
    
    func saveAPIKey() {
        summarizationFactory.setOpenAIKey(apiKey)
        hasAPIKey = true
        apiKey = ""
    }
    
    func toggleAPIKeyVisibility() {
        showingAPIKey.toggle()
    }
    
    private func checkAPIKey() {
        hasAPIKey = summarizationFactory.hasOpenAIKey()
    }
}
