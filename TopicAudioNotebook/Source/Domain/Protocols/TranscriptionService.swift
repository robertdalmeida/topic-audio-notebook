import Foundation
import Combine

struct TranscriptionResult: Sendable {
    let transcript: String
    let isFinal: Bool
    let confidence: Float?
    
    init(transcript: String, isFinal: Bool = true, confidence: Float? = nil) {
        self.transcript = transcript
        self.isFinal = isFinal
        self.confidence = confidence
    }
}

enum TranscriptionProvider: String, CaseIterable, Codable {
    case sfSpeechRecognizer = "Apple Speech"
    case speechTranscriber = "Speech Transcriber"
    
    var description: String {
        switch self {
        case .sfSpeechRecognizer:
            return "Uses SFSpeechRecognizer for speech-to-text (iOS 10+)"
        case .speechTranscriber:
            return "Uses SpeechTranscriber for advanced on-device transcription (iOS 26+)"
        }
    }
    
    var icon: String {
        switch self {
        case .sfSpeechRecognizer:
            return "waveform"
        case .speechTranscriber:
            return "waveform.badge.mic"
        }
    }
    
    var isAvailable: Bool {
        switch self {
        case .sfSpeechRecognizer:
            return true
        case .speechTranscriber:
            return SpeechTranscriberAvailability.isAvailable
        }
    }
    
    static var availableProviders: [TranscriptionProvider] {
        allCases.filter { $0.isAvailable }
    }
}

enum SpeechTranscriberAvailability {
    static var isAvailable: Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            return true
        }
        return false
    }
}

enum TranscriptionServiceError: LocalizedError {
    case notAuthorized
    case recognizerUnavailable
    case recognitionFailed(String)
    case audioSessionFailed(String)
    case notSupported
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .recognizerUnavailable:
            return "Speech recognizer is not available."
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        case .audioSessionFailed(let message):
            return "Audio session setup failed: \(message)"
        case .notSupported:
            return "This transcription provider is not supported on this device."
        }
    }
}

protocol TranscriptionServiceProtocol: Sendable {
    var providerType: TranscriptionProvider { get }
    
    func transcribe(audioURL: URL) async throws -> String
    func requestAuthorization() async -> Bool
}

@MainActor
protocol LiveTranscriptionServiceProtocol: AnyObject {
    var transcript: String { get }
    var isTranscribing: Bool { get }
    var errorMessage: String? { get }
    var transcriptPublisher: AnyPublisher<String, Never> { get }
    var providerType: TranscriptionProvider { get }
    
    func startTranscribing() async
    func stopTranscribing()
}
