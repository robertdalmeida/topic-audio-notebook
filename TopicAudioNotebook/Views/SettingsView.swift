import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var showingAPIKey = false
    @State private var hasAPIKey = false
    
    var body: some View {
        NavigationStack {
            Form {
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
}

#Preview {
    SettingsView()
}
