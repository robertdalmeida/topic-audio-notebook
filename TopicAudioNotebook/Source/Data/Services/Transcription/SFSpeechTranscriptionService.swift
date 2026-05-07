import Foundation
import Speech

actor SFSpeechTranscriptionService: TranscriptionServiceProtocol {
    let providerType: TranscriptionProvider = .sfSpeechRecognizer
    
    func transcribe(audioURL: URL) async throws -> String {
        let fileExists = FileManager.default.fileExists(atPath: audioURL.path)
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int64) ?? 0
        log.info("""
            🎤 [SFSpeech] Starting transcription:
              File: \(audioURL.lastPathComponent)
              Path: \(audioURL.path)
              Exists: \(fileExists)
              Size: \(fileSize) bytes
            """, category: .transcription)

        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("🎤 [SFSpeech] Authorization denied", category: .transcription)
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
            log.error("🎤 [SFSpeech] Recognizer unavailable", category: .transcription)
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        log.info("🎤 [SFSpeech] Creating recognition request for: \(audioURL.path)", category: .transcription)
        let request = SFSpeechURLRecognitionRequest(url: audioURL)
        request.shouldReportPartialResults = false
        request.addsPunctuation = true
        
        return try await withCheckedThrowingContinuation { continuation in
            recognizer.recognitionTask(with: request) { result, error in
                if let error = error {
                    let nsError = error as NSError
                    log.error("""
                        🎤 [SFSpeech] Recognition failed:
                          Error: \(error.localizedDescription)
                          Domain: \(nsError.domain)
                          Code: \(nsError.code)
                          UserInfo: \(nsError.userInfo)
                          URL: \(audioURL.path)
                        """, category: .transcription)
                    continuation.resume(throwing: TranscriptionServiceError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let result = result, result.isFinal else { return }
                
                let transcript = result.bestTranscription.formattedString
                log.info("🎤 [SFSpeech] Transcription complete (\(transcript.count) chars)", category: .transcription)
                continuation.resume(returning: transcript)
            }
        }
    }
}
