import Foundation
import AVFoundation
import Combine

@MainActor
class AudioPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playbackRate: Float = 1.0
    @Published var errorMessage: String?
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    var formattedCurrentTime: String {
        formatTime(currentTime)
    }
    
    var formattedDuration: String {
        formatTime(duration)
    }
    
    var progress: Double {
        guard duration > 0 else { return 0 }
        return currentTime / duration
    }
    
    func load(url: URL) {
        log.info("[AudioPlayer] Loading audio from: \(url.lastPathComponent)", category: .audio)
        stop()
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true
            duration = audioPlayer?.duration ?? 0
            currentTime = 0
        } catch {
            log.error("[AudioPlayer] Failed to load audio: \(error.localizedDescription)", category: .audio)
            errorMessage = "Failed to load audio: \(error.localizedDescription)"
        }
    }
    
    func play() {
        guard let player = audioPlayer else { 
            log.warning("[AudioPlayer] Attempted to play without loaded audio", category: .audio)
            return 
        }
        log.info("[AudioPlayer] Starting playback", category: .audio)
        player.rate = playbackRate
        player.play()
        isPlaying = true
        startTimer()
    }
    
    func pause() {
        log.info("[AudioPlayer] Pausing playback", category: .audio)
        audioPlayer?.pause()
        isPlaying = false
        stopTimer()
    }
    
    func stop() {
        if audioPlayer != nil {
            log.info("[AudioPlayer] Stopping playback", category: .audio)
        }
        audioPlayer?.stop()
        audioPlayer = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func seekToProgress(_ progress: Double) {
        let time = duration * progress
        seek(to: time)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            audioPlayer?.rate = rate
        }
    }
    
    func skipForward(_ seconds: TimeInterval = 15) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
    }
    
    func skipBackward(_ seconds: TimeInterval = 15) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentTime()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateCurrentTime() {
        currentTime = audioPlayer?.currentTime ?? 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
            currentTime = 0
            stopTimer()
        }
    }
    
    nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            errorMessage = "Playback error: \(error?.localizedDescription ?? "Unknown error")"
            isPlaying = false
            stopTimer()
        }
    }
}
