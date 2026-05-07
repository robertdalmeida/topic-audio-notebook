import Foundation

final class TranscriptionServiceFactory: @unchecked Sendable {
    static let shared = TranscriptionServiceFactory()
    
    private lazy var sfSpeechService = SFSpeechTranscriptionService()
    private var _speechTranscriberService: (any TranscriptionServiceProtocol)?
    private var speechTranscriberServiceCreated = false
    
    private static let providerKey = "TranscriptionProvider"
    
    private init() {
        log.info("TranscriptionServiceFactory initialized", category: .transcription)
    }
    
    private var speechTranscriberService: (any TranscriptionServiceProtocol)? {
        if !speechTranscriberServiceCreated {
            speechTranscriberServiceCreated = true
            if #available(iOS 26.0, macOS 26.0, *) {
                log.info("Creating SpeechTranscriberService (lazy)", category: .transcription)
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
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.providerKey)
        }
    }
    
    var currentService: any TranscriptionServiceProtocol {
        log.debug("Getting currentService for provider: \(currentProvider)", category: .transcription)
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
        log.info("Setting provider to: \(provider)", category: .transcription)
        guard provider.isAvailable else {
            log.warning("Provider \(provider) is not available", category: .transcription)
            return
        }
        currentProvider = provider
    }
    
    @MainActor
    func createLiveTranscriber() -> any LiveTranscriptionServiceProtocol {
        log.info("Creating live transcriber for provider: \(currentProvider)", category: .transcription)
        switch currentProvider {
        case .sfSpeechRecognizer:
            return SFSpeechLiveTranscriber()
        case .speechTranscriber:
            log.warning("SpeechTranscriber live service not yet stable, falling back to SFSpeechRecognizer", category: .transcription)
            return SFSpeechLiveTranscriber()
        }
    }
    
    var isSpeechTranscriberAvailable: Bool {
        SpeechTranscriberAvailability.isAvailable
    }
}
