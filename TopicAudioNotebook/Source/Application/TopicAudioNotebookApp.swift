import SwiftUI

@main
struct TopicAudioNotebookApp: App {
    @StateObject private var repository = TopicRepository()
    
    init() {
        logConfiguration()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView(repository: repository)
                .environmentObject(repository)
        }
    }
    
    private func logConfiguration() {
        let transcriptionProvider = TranscriptionServiceFactory.shared.currentProvider
        let summarizationProvider = SummarizationServiceFactory.shared.currentProvider
        let storageType = StorageManager.shared.currentStorageType
        let hasOpenAIKey = SummarizationServiceFactory.shared.hasOpenAIKey()
        
        log.info("""
        [TopicAudioNotebookApp] Current Configuration:
        - Transcription Provider: \(transcriptionProvider.rawValue)
        - Summarization Provider: \(summarizationProvider.rawValue)
        - Storage Type: \(storageType.rawValue)
        - OpenAI API Key: \(hasOpenAIKey ? "Configured" : "Not Found")
        """, category: .general)
    }
}
