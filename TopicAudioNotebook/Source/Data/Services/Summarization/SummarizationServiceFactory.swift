import Foundation

final class SummarizationServiceFactory: @unchecked Sendable {
    static let shared = SummarizationServiceFactory()
    
    private let onDeviceService = OnDeviceSummarizationService()
    private let openAIService = OpenAISummarizationService()
    private let mlxService = MLXSummarizationService()
    private let mlxLlamaService = MLXLlamaSummarizationService()
    private var foundationModelsService: (any SummarizationService)?
    
    private static let providerKey = "SummarizationProvider"
    
    private init() {
        if #available(iOS 26.0, macOS 26.0, *) {
            foundationModelsService = FoundationModelsSummarizationService()
        }
    }
    
    var currentProvider: SummarizationProvider {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: Self.providerKey),
                  let provider = SummarizationProvider(rawValue: rawValue) else {
                return .onDevice
            }
            return provider
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.providerKey)
        }
    }
    
    var currentService: any SummarizationService {
        switch currentProvider {
        case .onDevice:
            return onDeviceService
        case .foundationModels:
            return foundationModelsService ?? onDeviceService
        case .mlxPhi:
            return mlxService
        case .mlxLlama:
            return mlxLlamaService
        case .openAI:
            return openAIService
        }
    }
    
    func service(for provider: SummarizationProvider) -> any SummarizationService {
        switch provider {
        case .onDevice:
            return onDeviceService
        case .foundationModels:
            return foundationModelsService ?? onDeviceService
        case .mlxPhi:
            return mlxService
        case .mlxLlama:
            return mlxLlamaService
        case .openAI:
            return openAIService
        }
    }
    
    var isFoundationModelsAvailable: Bool {
        FoundationModelsAvailability.isAvailable
    }
    
    func setProvider(_ provider: SummarizationProvider) {
        currentProvider = provider
    }
    
    func isServiceReady() async -> Bool {
        let service = currentService
        if let loadable = service as? LoadableSummarizationService {
            return await loadable.isLoaded
        }
        return true
    }
    
    func isServiceLoading() async -> Bool {
        let service = currentService
        if let loadable = service as? LoadableSummarizationService {
            return await loadable.isLoading
        }
        return false
    }
    
    func preloadCurrentService(progressHandler: (@Sendable (Double) -> Void)? = nil) async throws {
        let service = currentService
        if let loadable = service as? LoadableSummarizationService {
            try await loadable.preloadModel(progressHandler: progressHandler)
        }
    }
    
    func getLoadingProgress() async -> Double {
        let service = currentService
        if let loadable = service as? LoadableSummarizationService {
            return await loadable.loadingProgress
        }
        return 1.0
    }
    
    func requiresPreloading() -> Bool {
        return currentService is LoadableSummarizationService
    }
    
    func hasOpenAIKey() -> Bool {
        guard let key = UserDefaults.standard.string(forKey: "OpenAI_API_Key") else {
            return false
        }
        return !key.isEmpty
    }
    
    func setOpenAIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "OpenAI_API_Key")
    }
}
