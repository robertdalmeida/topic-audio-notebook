import SwiftUI

@main
struct TopicAudioNotebookApp: App {
    @StateObject private var repository = TopicRepository()
    
    var body: some Scene {
        WindowGroup {
            RootView(repository: repository)
                .environmentObject(repository)
        }
    }
}
