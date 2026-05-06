import Foundation
import Speech
import AVFoundation

@MainActor
class LiveTranscriber: ObservableObject {
    @Published var transcript: String = ""
    @Published var isTranscribing: Bool = false
    @Published var errorMessage: String?
    
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioEngine: AVAudioEngine?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    
    func startTranscribing() async {
        let authorized = await requestAuthorization()
        guard authorized else {
            errorMessage = "Speech recognition not authorized"
            return
        }
        
        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = "Speech recognizer not available"
            return
        }
        
        do {
            try await setupAudioSession()
            try startRecognition(with: recognizer)
            isTranscribing = true
        } catch {
            errorMessage = "Failed to start transcription: \(error.localizedDescription)"
        }
    }
    
    func stopTranscribing() {
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
