import Foundation
import Speech
import AVFoundation

@available(iOS 26.0, macOS 26.0, *)
actor SpeechTranscriberService: TranscriptionServiceProtocol {
    let providerType: TranscriptionProvider = .speechTranscriber
    
    func transcribe(audioURL: URL) async throws -> String {
        log.info("[SpeechTranscriberService] Starting transcription for \(audioURL.lastPathComponent)", category: .transcription)

        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("[SpeechTranscriberService] Speech recognition authorization denied", category: .transcription)
            throw TranscriptionServiceError.notAuthorized
        }
        
        return try await performTranscription(audioURL: audioURL)
    }
    
    func requestAuthorization() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func performTranscription(audioURL: URL) async throws -> String {
        guard let locale = await DictationTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
            log.error("[SpeechTranscriberService] DictationTranscriber unavailable for locale en-US", category: .transcription)
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        let transcriber = DictationTranscriber(locale: locale, preset: .longDictation)
        
        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            log.info("[SpeechTranscriberService] Downloading required assets...", category: .transcription)
            try await installationRequest.downloadAndInstall()
        }
        
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: audioURL)
        } catch {
            log.error("[SpeechTranscriberService] Failed to open audio file: \(error.localizedDescription)", category: .transcription)
            throw TranscriptionServiceError.recognitionFailed("Failed to open audio file")
        }
        
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        
        let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile)
        
        if let lastSampleTime {
            try await analyzer.finalizeAndFinish(through: lastSampleTime)
        } else {
            log.error("[SpeechTranscriberService] No audio data found in \(audioURL.lastPathComponent)", category: .transcription)
            throw TranscriptionServiceError.recognitionFailed("No audio data found")
        }
        
        var fullTranscript = ""
        for try await result in transcriber.results {
            fullTranscript = String(result.text.characters)
        }
        
        log.info("[SpeechTranscriberService] Transcription complete (\(fullTranscript.count) chars)", category: .transcription)
        return fullTranscript
    }
}
