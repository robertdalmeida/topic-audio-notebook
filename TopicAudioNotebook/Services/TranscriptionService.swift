import Foundation
import Speech

actor TranscriptionService {
    static let shared = TranscriptionService()
    
    private init() {}
    
    func transcribe(audioURL: URL) async throws -> String {
        let authorized = await requestAuthorization()
        guard authorized else {
            throw TranscriptionError.notAuthorized
        }
        
        return try await performTranscription(audioURL: audioURL)
    }
    
    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func performTranscription(audioURL: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            throw TranscriptionError.recognizerUnavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    continuation.resume(throwing: TranscriptionError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                let transcript = result.bestTranscription.formattedString
                continuation.resume(returning: transcript)
            }
        }
    }
}

enum TranscriptionError: LocalizedError {
    case notAuthorized
    case recognizerUnavailable
    case recognitionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            return "Speech recognition not authorized. Please enable in Settings."
        case .recognizerUnavailable:
            return "Speech recognizer is not available."
        case .recognitionFailed(let message):
            return "Recognition failed: \(message)"
        }
    }
}
