import Foundation
import Speech
import AVFoundation

@available(iOS 26.0, macOS 26.0, *)
actor SpeechTranscriberService: TranscriptionServiceProtocol {
    let providerType: TranscriptionProvider = .speechTranscriber
    
    func transcribe(audioURL: URL) async throws -> String {
        log.info("🧠 [SpeechTranscriberService] transcribe() called", category: .transcription)
        log.info("🧠 [SpeechTranscriberService] Audio URL: \(audioURL.lastPathComponent)", category: .transcription)

        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("🧠 [SpeechTranscriberService] Not authorized", category: .transcription)
            throw TranscriptionServiceError.notAuthorized
        }
        
        log.info("🧠 [SpeechTranscriberService] Authorization granted", category: .transcription)

        guard await DictationTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) != nil else {
            log.error("🧠 [SpeechTranscriberService] No supported locale for en-US", category: .transcription)
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        return try await performTranscription(audioURL: audioURL)
    }
    
    func requestAuthorization() async -> Bool {
        log.debug("Requesting speech authorization...", category: .transcription)
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                log.debug("Authorization status: \(status.rawValue)", category: .transcription)
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func performTranscription(audioURL: URL) async throws -> String {
        log.info("🧠 [SpeechTranscriberService] Starting transcription...", category: .transcription)

        guard let locale = await DictationTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
            log.error("🧠 [SpeechTranscriberService] No supported locale found", category: .transcription)
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        log.info("🧠 [SpeechTranscriberService] Using locale: \(locale.identifier)", category: .transcription)

        let transcriber = DictationTranscriber(locale: locale, preset: .longDictation)
        
        log.info("🧠 [SpeechTranscriberService] Checking assets...", category: .transcription)
        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            log.info("🧠 [SpeechTranscriberService] Installing assets...", category: .transcription)
            try await installationRequest.downloadAndInstall()
            log.info("🧠 [SpeechTranscriberService] Assets installed", category: .transcription)
        } else {
            log.info("🧠 [SpeechTranscriberService] Assets ready", category: .transcription)
        }
        
        guard FileManager.default.fileExists(atPath: audioURL.path) else {
            log.error("🧠 [SpeechTranscriberService] File not found: \(audioURL.path)", category: .transcription)
            throw TranscriptionServiceError.recognitionFailed("Audio file not found")
        }
        
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: audioURL)
            log.info("🧠 [SpeechTranscriberService] Audio format: \(audioFile.processingFormat)", category: .transcription)
        } catch {
            log.error("🧠 [SpeechTranscriberService] Failed to open file: \(error.localizedDescription)", category: .transcription)
            throw TranscriptionServiceError.recognitionFailed("Failed to open audio file")
        }
        
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        
        log.info("🧠 [SpeechTranscriberService] Analyzing audio...", category: .transcription)
        let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile)
        
        if let lastSampleTime {
            log.info("🧠 [SpeechTranscriberService] Finalizing analysis...", category: .transcription)
            try await analyzer.finalizeAndFinish(through: lastSampleTime)
        } else {
            log.error("🧠 [SpeechTranscriberService] No audio data found", category: .transcription)
            throw TranscriptionServiceError.recognitionFailed("No audio data found")
        }
        
        log.info("🧠 [SpeechTranscriberService] Collecting results...", category: .transcription)
        var fullTranscript = ""
        
        for try await result in transcriber.results {
            fullTranscript = String(result.text.characters)
        }
        
        log.info("🧠 [SpeechTranscriberService] Transcription complete, length: \(fullTranscript.count) chars", category: .transcription)
        return fullTranscript
    }
}
