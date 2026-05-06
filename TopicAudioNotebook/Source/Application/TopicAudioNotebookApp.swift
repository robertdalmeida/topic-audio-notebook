import SwiftUI

@main
struct TopicAudioNotebookApp: App {
    @StateObject private var repository = TopicRepository()
    
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: TopicsListViewModel(repository: repository))
                .environmentObject(repository)
        }
    }
}
