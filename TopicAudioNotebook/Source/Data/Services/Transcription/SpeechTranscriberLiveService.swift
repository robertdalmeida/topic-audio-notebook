import Foundation
import Speech
import AVFoundation
import Combine

@available(iOS 26.0, macOS 26.0, *)
@MainActor
final class SpeechTranscriberLiveService: ObservableObject, LiveTranscriptionServiceProtocol {
    @Published private(set) var transcript: String = ""
    @Published private(set) var isTranscribing: Bool = false
    @Published var errorMessage: String?
    
    let providerType: TranscriptionProvider = .speechTranscriber
    
    var transcriptPublisher: AnyPublisher<String, Never> {
        $transcript.eraseToAnyPublisher()
    }
    
    private var transcriptionTask: Task<Void, Never>?
    private var analysisTask: Task<Void, Never>?
    private var audioEngine: AVAudioEngine?
    private var inputContinuation: AsyncStream<AnalyzerInput>.Continuation?
    
    func startTranscribing() async {
        log.info("🧠 [SpeechTranscriberLive] Starting live transcription...", category: .transcription)
        
        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("🧠 [SpeechTranscriberLive] Not authorized", category: .transcription)
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        guard SpeechTranscriber.isAvailable else {
            log.error("🧠 [SpeechTranscriberLive] Not available on this device", category: .transcription)
            errorMessage = "SpeechTranscriber not available on this device"
            return
        }
        
        do {
            try await setupAudioSession()
            try await startRecognition()
            isTranscribing = true
            log.info("🧠 [SpeechTranscriberLive] Live transcription started", category: .transcription)
        } catch {
            log.error("🧠 [SpeechTranscriberLive] Failed to start: \(error.localizedDescription)", category: .transcription)
            errorMessage = "Failed to start transcription: \(error.localizedDescription)"
        }
    }
    
    func stopTranscribing() {
        log.info("🧠 [SpeechTranscriberLive] Stopping live transcription", category: .transcription)
        
        inputContinuation?.finish()
        inputContinuation = nil
        
        transcriptionTask?.cancel()
        transcriptionTask = nil
        
        analysisTask?.cancel()
        analysisTask = nil
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        
        isTranscribing = false
    }
    
    private func requestAuthorization() async -> Bool {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    private func setupAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
    }
    
    private func startRecognition() async throws {
        guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: "en-US")) else {
            throw TranscriptionServiceError.recognizerUnavailable
        }
        
        let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)
        
        if let installationRequest = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await installationRequest.downloadAndInstall()
        }
        
        let (inputSequence, continuation) = AsyncStream.makeStream(of: AnalyzerInput.self)
        self.inputContinuation = continuation
        
        let analyzer = SpeechAnalyzer(modules: [transcriber])
        
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            guard let self = self else { return }
            let input = AnalyzerInput(buffer: buffer)
            self.inputContinuation?.yield(input)
        }
        
        engine.prepare()
        try engine.start()
        
        analysisTask = Task.detached { [analyzer, inputSequence] in
            _ = try? await analyzer.analyzeSequence(inputSequence)
        }
        
        transcriptionTask = Task { [weak self, transcriber] in
            do {
                for try await result in transcriber.results {
                    guard !Task.isCancelled else { break }
                    await MainActor.run {
                        self?.transcript = String(result.text.characters)
                    }
                }
            } catch {
                await MainActor.run {
                    self?.errorMessage = "Transcription error: \(error.localizedDescription)"
                    self?.stopTranscribing()
                }
            }
        }
    }
}
