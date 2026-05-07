import Foundation
import AVFoundation
import Combine

enum RecordingState {
    case idle
    case recording
    case paused
}

@MainActor
class AudioRecorder: NSObject, ObservableObject {
    @Published var state: RecordingState = .idle
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?
    private var currentFileURL: URL?
    private var pausedTime: TimeInterval = 0
    
    var isRecording: Bool { state == .recording }
    var isPaused: Bool { state == .paused }
    var isIdle: Bool { state == .idle }
    var hasActiveSession: Bool { state != .idle }
    
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    
    func startRecording(to directory: URL) async -> URL? {
        log.info("[AudioRecorder] Starting recording to directory: \(directory.lastPathComponent)", category: .audio)
        let hasPermission = await requestPermission()
        guard hasPermission else {
            log.error("[AudioRecorder] Microphone permission denied", category: .audio)
            errorMessage = "Microphone permission denied"
            return nil
        }
        
        let fileName = "recording_\(Date().timeIntervalSince1970).wav"
        let fileURL = directory.appendingPathComponent(fileName)
        currentFileURL = fileURL
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
            
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
            state = .recording
            recordingTime = 0
            pausedTime = 0
            startTimers()
            
            return fileURL
        } catch {
            log.error("[AudioRecorder] Failed to start recording: \(error.localizedDescription)", category: .audio)
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            return nil
        }
    }
    
    func pauseRecording() {
        guard state == .recording, let recorder = audioRecorder else { return }
        log.info("[AudioRecorder] Pausing recording", category: .audio)
        recorder.pause()
        pausedTime = recordingTime
        stopTimers()
        state = .paused
        audioLevel = 0
    }
    
    func resumeRecording() {
        guard state == .paused, let recorder = audioRecorder else { return }
        log.info("[AudioRecorder] Resuming recording", category: .audio)
        recorder.record()
        state = .recording
        startTimers()
    }
    
    func stopRecording() -> (URL, TimeInterval)? {
        guard let recorder = audioRecorder, hasActiveSession else { return nil }
        
        let duration = recorder.currentTime
        log.info("[AudioRecorder] Stopping recording, duration: \(duration)s", category: .audio)
        recorder.stop()
        stopTimers()
        
        state = .idle
        audioLevel = 0
        
        guard let url = currentFileURL else { return nil }
        return (url, duration)
    }
    
    func cancelRecording() {
        audioRecorder?.stop()
        stopTimers()
        
        if let url = currentFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        
        state = .idle
        recordingTime = 0
        pausedTime = 0
        audioLevel = 0
        currentFileURL = nil
    }
    
    private func startTimers() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingTime += 1
            }
        }
        
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateAudioLevel()
            }
        }
    }
    
    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        levelTimer?.invalidate()
        levelTimer = nil
    }
    
    private func updateAudioLevel() {
        audioRecorder?.updateMeters()
        let level = audioRecorder?.averagePower(forChannel: 0) ?? -160
        let normalizedLevel = max(0, (level + 60) / 60)
        audioLevel = normalizedLevel
    }
}

extension AudioRecorder: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            if !flag {
                errorMessage = "Recording finished unexpectedly"
            }
        }
    }
    
    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        Task { @MainActor in
            errorMessage = "Recording error: \(error?.localizedDescription ?? "Unknown error")"
        }
    }
}
