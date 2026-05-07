import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SFSpeechLiveTranscriber: ObservableObject, LiveTranscriptionServiceProtocol {
    @Published private(set) var transcript: String = ""
    @Published private(set) var isTranscribing: Bool = false
    @Published var errorMessage: String?
    
    let providerType: TranscriptionProvider = .sfSpeechRecognizer
    
    var transcriptPublisher: AnyPublisher<String, Never> {
        $transcript.eraseToAnyPublisher()
    }
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func startTranscribing() async {
        log.info("🎤 [SFSpeechLive] Starting live transcription...", category: .transcription)
        
        let authorized = await requestAuthorization()
        guard authorized else {
            log.error("🎤 [SFSpeechLive] Not authorized", category: .transcription)
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            log.error("🎤 [SFSpeechLive] Recognizer not available", category: .transcription)
            errorMessage = "Speech recognizer not available"
            return
        }
        
        do {
            try await setupAudioSession()
            try startRecognition(with: recognizer)
            isTranscribing = true
            log.info("🎤 [SFSpeechLive] Live transcription started", category: .transcription)
        } catch {
            log.error("🎤 [SFSpeechLive] Failed to start: \(error.localizedDescription)", category: .transcription)
            errorMessage = "Failed to start transcription: \(error.localizedDescription)"
        }
    }
    
    func stopTranscribing() {
        log.info("🎤 [SFSpeechLive] Stopping live transcription", category: .transcription)
        
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
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
    
    private func startRecognition(with recognizer: SFSpeechRecognizer) throws {
        recognitionTask?.cancel()
        recognitionTask = nil
        
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = true
        
        if #available(iOS 16, *) {
            request.requiresOnDeviceRecognition = false
        }
        
        recognitionRequest = request
        
        let engine = AVAudioEngine()
        audioEngine = engine
        
        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }
        
        engine.prepare()
        try engine.start()
        
        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                if let result = result {
                    self?.transcript = result.bestTranscription.formattedString
                }
                
                if error != nil || result?.isFinal == true {
                    self?.stopTranscribing()
                }
            }
        }
    }
}
