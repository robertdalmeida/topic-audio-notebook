import Foundation
import Speech
import AVFoundation

@available(iOS 26.0, macOS 26.0, *)
actor SpeechTranscriberService: TranscriptionServiceProtocol {
    let providerType: TranscriptionProvider = .speechTranscriber
    
    func transcribe(audioURL: URL) async throws -> String {
        let fileExists = FileManager.default.fileExists(atPath: audioURL.path)
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int64) ?? 0
        log.info("""
            🧠 [DictationTranscriber] Starting transcription:
              File: \(audioURL.lastPathComponent)
              Path: \(audioURL.path)
              Exists: \(fileExists)
              Size: \(fileSize) bytes
            """, category: .transcription)

        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("🧠 [DictationTranscriber] Authorization denied", category: .transcription)
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
            log.error("🧠 [DictationTranscriber] Unavailable for locale en-US", category: .transcription)
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        log.info("🧠 [DictationTranscriber] Creating transcriber with locale: \(locale.identifier)", category: .transcription)
        let transcriber = DictationTranscriber(locale: locale, preset: .longDictation)
        
        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            log.info("🧠 [DictationTranscriber] Downloading required assets...", category: .transcription)
            try await installationRequest.downloadAndInstall()
            log.info("🧠 [DictationTranscriber] Assets downloaded", category: .transcription)
        }
        
        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: audioURL)
            let format = audioFile.processingFormat
            log.info("""
                🧠 [DictationTranscriber] Audio file opened:
                  Sample rate: \(format.sampleRate) Hz
                  Channels: \(format.channelCount)
                  Length: \(audioFile.length) frames
                  Duration: \(Double(audioFile.length) / format.sampleRate) seconds
                """, category: .transcription)
        } catch {
            let nsError = error as NSError
            log.error("""
                🧠 [DictationTranscriber] Failed to open audio file:
                  Error: \(error.localizedDescription)
                  Domain: \(nsError.domain)
                  Code: \(nsError.code)
                  UserInfo: \(nsError.userInfo)
                  URL: \(audioURL.path)
                """, category: .transcription)
            throw TranscriptionServiceError.recognitionFailed("Failed to open audio file")
        }
        
        log.info("🧠 [DictationTranscriber] Starting analysis...", category: .transcription)
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        
        do {
            let lastSampleTime = try await analyzer.analyzeSequence(from: audioFile)
            
            if let lastSampleTime {
                log.info("🧠 [DictationTranscriber] Finalizing analysis at sample time: \(lastSampleTime)", category: .transcription)
                try await analyzer.finalizeAndFinish(through: lastSampleTime)
            } else {
                log.error("🧠 [DictationTranscriber] No audio data found in \(audioURL.lastPathComponent)", category: .transcription)
                throw TranscriptionServiceError.recognitionFailed("No audio data found")
            }
        } catch {
            let nsError = error as NSError
            log.error("""
                🧠 [DictationTranscriber] Analysis failed:
                  Error: \(error.localizedDescription)
                  Domain: \(nsError.domain)
                  Code: \(nsError.code)
                  URL: \(audioURL.path)
                """, category: .transcription)
            throw error
        }
        
        var fullTranscript = ""
        for try await result in transcriber.results {
            fullTranscript = String(result.text.characters)
        }
        
        log.info("🧠 [DictationTranscriber] Transcription complete (\(fullTranscript.count) chars)", category: .transcription)
        return fullTranscript
    }
}
