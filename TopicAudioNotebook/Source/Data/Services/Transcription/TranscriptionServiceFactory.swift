import Foundation

final class TranscriptionServiceFactory: @unchecked Sendable {
    static let shared = TranscriptionServiceFactory()
    
    private lazy var sfSpeechService = SFSpeechTranscriptionService()
    private var _speechTranscriberService: (any TranscriptionServiceProtocol)?
    private var speechTranscriberServiceCreated = false
    
    private static let providerKey = "TranscriptionProvider"
    
    private init() {
        log.info("[TranscriptionServiceFactory] Initializing", category: .transcription)
    }
    
    private var speechTranscriberService: (any TranscriptionServiceProtocol)? {
        if !speechTranscriberServiceCreated {
            speechTranscriberServiceCreated = true
            if #available(iOS 26.0, macOS 26.0, *) {
                log.info("[TranscriptionServiceFactory] Creating SpeechTranscriberService", category: .transcription)
                _speechTranscriberService = SpeechTranscriberService()
            }
        }
        return _speechTranscriberService
    }
    
    var currentProvider: TranscriptionProvider {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: Self.providerKey),
                  let provider = TranscriptionProvider(rawValue: rawValue),
                  provider.isAvailable else {
                return .sfSpeechRecognizer
            }
            return provider
        }
        set {
            log.info("[TranscriptionServiceFactory] Provider updated to: \(newValue)", category: .transcription)
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.providerKey)
        }
    }
    
    var currentService: any TranscriptionServiceProtocol {
        switch currentProvider {
        case .sfSpeechRecognizer:
            return sfSpeechService
        case .speechTranscriber:
            return speechTranscriberService ?? sfSpeechService
        }
    }
    
    func service(for provider: TranscriptionProvider) -> any TranscriptionServiceProtocol {
        switch provider {
        case .sfSpeechRecognizer:
            return sfSpeechService
        case .speechTranscriber:
            return speechTranscriberService ?? sfSpeechService
        }
    }
    
    func setProvider(_ provider: TranscriptionProvider) {
        guard provider.isAvailable else {
            log.warning("[TranscriptionServiceFactory] Provider \(provider) is not available on this device", category: .transcription)
            return
        }
        currentProvider = provider
    }
    
    @MainActor
    func createLiveTranscriber() -> any LiveTranscriptionServiceProtocol {
        log.info("[TranscriptionServiceFactory] Creating live transcriber for: \(currentProvider)", category: .transcription)
        switch currentProvider {
        case .sfSpeechRecognizer:
            return SFSpeechLiveTranscriber()
        case .speechTranscriber:
            log.warning("[TranscriptionServiceFactory] SpeechTranscriber live service not yet stable, falling back to SFSpeechLiveTranscriber", category: .transcription)
            return SFSpeechLiveTranscriber()
        }
    }
    
    var isSpeechTranscriberAvailable: Bool {
        SpeechTranscriberAvailability.isAvailable
    }
}
