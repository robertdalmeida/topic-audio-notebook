import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject var viewModel: SettingsViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                storageSection
                summarizationSection
                
                if viewModel.selectedSummarizationProvider == .openAI {
                    apiKeySection
                    resourcesSection
                }
                
                aboutSection
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
            .alert("Switch Storage?", isPresented: $viewModel.showingStorageConfirmation) {
                Button("Cancel", role: .cancel, action: viewModel.cancelStorageSwitch)
                Button("Switch", action: viewModel.confirmStorageSwitch)
            } message: {
                Text("This will migrate all your data to \(viewModel.selectedStorageType.rawValue). This may take a moment.")
            }
        }
    }
    
    // MARK: - Storage Section
    
    private var storageSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "externaldrive")
                        .font(.title2)
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading) {
                        Text("Storage Provider")
                            .font(.headline)
                        Text(viewModel.currentStorageType.rawValue)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                Text(viewModel.currentStorageType.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            
            Picker("Storage Type", selection: $viewModel.selectedStorageType) {
                ForEach(StorageType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .disabled(viewModel.isSwitchingStorage)
            .onChange(of: viewModel.selectedStorageType) { _, newValue in
                viewModel.onStorageTypeChanged(to: newValue)
            }
            
            if viewModel.isSwitchingStorage {
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
    }
    
    // MARK: - Summarization Section
    
    private var summarizationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "brain")
                        .font(.title2)
                        .foregroundStyle(.purple)
                    
                    VStack(alignment: .leading) {
                        Text("Summarization Provider")
                            .font(.headline)
                        Text(viewModel.selectedSummarizationProvider.rawValue)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                
                Text(viewModel.selectedSummarizationProvider.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            
            Picker("Provider", selection: $viewModel.selectedSummarizationProvider) {
                ForEach(SummarizationProvider.availableProviders, id: \.self) { provider in
                    HStack {
                        Image(systemName: provider.icon)
                        Text(provider.rawValue)
                    }
                    .tag(provider)
                }
            }
            .onChange(of: viewModel.selectedSummarizationProvider) { _, newValue in
                viewModel.onSummarizationProviderChanged(to: newValue)
            }
        } header: {
            Text("Summarization")
        } footer: {
            Text(summarizationFooterText)
        }
    }
    
    private var summarizationFooterText: String {
        var parts: [String] = []
        parts.append("On-Device uses Apple's NaturalLanguage framework and works offline.")
        if SummarizationProvider.foundationModels.isAvailable {
            parts.append("Apple Intelligence provides high-quality on-device AI summaries.")
        }
        parts.append("OpenAI provides cloud-based summaries but requires an API key.")
        return parts.joined(separator: " ")
    }
    
    // MARK: - API Key Section
    
    private var apiKeySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "key")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    
                    VStack(alignment: .leading) {
                        Text("OpenAI API Key")
                            .font(.headline)
                        Text(viewModel.hasAPIKey ? "Configured" : "Not configured")
                            .font(.caption)
                            .foregroundStyle(viewModel.hasAPIKey ? .green : .secondary)
                    }
                }
                
                Text("Required for OpenAI summarization.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
            
            HStack {
                if viewModel.showingAPIKey {
                    TextField("sk-...", text: $viewModel.apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                } else {
                    SecureField("sk-...", text: $viewModel.apiKey)
                }
                
                Button(action: viewModel.toggleAPIKeyVisibility) {
                    Image(systemName: viewModel.showingAPIKey ? "eye.slash" : "eye")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Button("Save API Key", action: viewModel.saveAPIKey)
                .disabled(!viewModel.canSaveAPIKey)
        } header: {
            Text("OpenAI Configuration")
        } footer: {
            Text("Your API key is stored securely on this device only.")
        }
    }
    
    // MARK: - Resources Section
    
    private var resourcesSection: some View {
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
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
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
}

#Preview {
    let repository = TopicRepository()
    return SettingsView(viewModel: SettingsViewModel(repository: repository))
        .environmentObject(repository)
}
