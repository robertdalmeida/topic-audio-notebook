import Foundation
import Speech

actor SFSpeechTranscriptionService: TranscriptionServiceProtocol {
    let providerType: TranscriptionProvider = .sfSpeechRecognizer
    
    func transcribe(audioURL: URL) async throws -> String {
        log.info("🎤 [SFSpeechTranscriptionService] transcribe() called", category: .transcription)
        log.info("🎤 [SFSpeechTranscriptionService] Audio URL: \(audioURL.lastPathComponent)", category: .transcription)

        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("🎤 [SFSpeechTranscriptionService] Not authorized", category: .transcription)
            throw TranscriptionServiceError.notAuthorized
        }
        
        log.info("🎤 [SFSpeechTranscriptionService] Authorization granted, starting transcription...", category: .transcription)
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
            log.error("🎤 [SFSpeechTranscriptionService] Recognizer unavailable", category: .transcription)
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        
        log.info("🎤 [SFSpeechTranscriptionService] Starting recognition task...", category: .transcription)

        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    log.error("🎤 [SFSpeechTranscriptionService] Recognition failed: \(error.localizedDescription)", category: .transcription)
                    continuation.resume(throwing: TranscriptionServiceError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                let transcript = result.bestTranscription.formattedString
                log.info("🎤 [SFSpeechTranscriptionService] Transcription complete, length: \(transcript.count) chars", category: .transcription)
                continuation.resume(returning: transcript)
            }
        }
    }
}
