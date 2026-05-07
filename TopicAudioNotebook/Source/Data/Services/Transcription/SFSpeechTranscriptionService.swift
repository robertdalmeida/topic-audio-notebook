import Foundation
import Speech

actor SFSpeechTranscriptionService: TranscriptionServiceProtocol {
    let providerType: TranscriptionProvider = .sfSpeechRecognizer
    
    func transcribe(audioURL: URL) async throws -> String {
        log.info("[SFSpeechTranscriptionService] Starting transcription for \(audioURL.lastPathComponent)", category: .transcription)

        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("[SFSpeechTranscriptionService] Speech recognition authorization denied", category: .transcription)
            throw TranscriptionServiceError.notAuthorized
        }
        
        return try await performTranscription(audioURL: audioURL)
    }
    
    func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func performTranscription(audioURL: URL) async throws -> String {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US")),
              recognizer.isAvailable else {
            log.error("[SFSpeechTranscriptionService] SFSpeechRecognizer unavailable", category: .transcription)
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    log.error("[SFSpeechTranscriptionService] Recognition failed: \(error.localizedDescription)", category: .transcription)
                    continuation.resume(throwing: TranscriptionServiceError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                let transcript = result.bestTranscription.formattedString
                log.info("[SFSpeechTranscriptionService] Transcription complete (\(transcript.count) chars)", category: .transcription)
                continuation.resume(returning: transcript)
            }
        }
    }
}
