import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var topicStore: TopicStore
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var showingAPIKey = false
    @State private var hasAPIKey = false
    @State private var selectedStorageType: StorageType = .file
    @State private var isSwitchingStorage = false
    @State private var showingStorageConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "externaldrive")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading) {
                                Text("Storage Provider")
                                    .font(.headline)
                                Text(topicStore.currentStorageType.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        Text(topicStore.currentStorageType.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    Picker("Storage Type", selection: $selectedStorageType) {
                        ForEach(StorageType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isSwitchingStorage)
                    .onChange(of: selectedStorageType) { _, newValue in
                        if newValue != topicStore.currentStorageType {
                            showingStorageConfirmation = true
                        }
                    }
                    
                    if isSwitchingStorage {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Migrating data...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Data Storage")
                } footer: {
                    Text("Switching storage will migrate all your data to the new provider.")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "brain")
                                .font(.title2)
                                .foregroundStyle(.purple)
                            
                            VStack(alignment: .leading) {
                                Text("OpenAI API Key")
                                    .font(.headline)
                                Text(hasAPIKey ? "Configured" : "Not configured")
                                    .font(.caption)
                                    .foregroundStyle(hasAPIKey ? .green : .secondary)
                            }
                        }
                        
                        Text("Required for AI-powered summary consolidation. Without it, a basic summary will be generated.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        if showingAPIKey {
                            TextField("sk-...", text: $apiKey)
                                .textContentType(.password)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        } else {
                            SecureField("sk-...", text: $apiKey)
                        }
                        
                        Button {
                            showingAPIKey.toggle()
                        } label: {
                            Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Button("Save API Key") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.trimmingCharacters(in: .whitespaces).isEmpty)
                } header: {
                    Text("AI Configuration")
                } footer: {
                    Text("Your API key is stored securely on this device only.")
                }
                
                Section {
                    Link(destination: URL(string: "https://platform.openai.com/api-keys")!) {
                        HStack {
                            Label("Get API Key", systemImage: "key")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Link(destination: URL(string: "https://platform.openai.com/docs/guides/speech-to-text")!) {
                        HStack {
                            Label("OpenAI Documentation", systemImage: "book")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Resources")
                }
                
                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Text("Transcription")
                        Spacer()
                        Text("Apple Speech Recognition")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                checkAPIKey()
                selectedStorageType = topicStore.currentStorageType
            }
            .alert("Switch Storage?", isPresented: $showingStorageConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedStorageType = topicStore.currentStorageType
                }
                Button("Switch") {
                    switchStorage()
                }
            } message: {
                Text("This will migrate all your data to \(selectedStorageType.rawValue). This may take a moment.")
            }
        }
    }
    
    private func saveAPIKey() {
        Task {
            await AIService.shared.setAPIKey(apiKey)
            hasAPIKey = true
            apiKey = ""
        }
    }
    
    private func checkAPIKey() {
        Task {
            hasAPIKey = await AIService.shared.hasAPIKey()
        }
    }
    
    private func switchStorage() {
        isSwitchingStorage = true
        Task {
            await topicStore.switchStorage(to: selectedStorageType)
            isSwitchingStorage = false
        }
    }
}

#Preview {
    SettingsView()
}
