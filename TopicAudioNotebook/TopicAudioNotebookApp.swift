import SwiftUI

@main
struct TopicAudioNotebookApp: App {
    @StateObject private var topicStore = TopicStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(topicStore)
        }
    }
}
