import SwiftUI

struct AudioPlayerSection: View {
    @ObservedObject var audioPlayer: AudioPlayer
    
    var body: some View {
        VStack(spacing: 16) {
            AudioProgressRing(
                progress: audioPlayer.progress,
                isPlaying: audioPlayer.isPlaying
            )
            
            AudioSeekBar(
                currentTime: audioPlayer.formattedCurrentTime,
                duration: audioPlayer.formattedDuration,
                progress: audioPlayer.progress,
                onSeek: { audioPlayer.seekToProgress($0) }
            )
            
            AudioPlaybackControls(
                isPlaying: audioPlayer.isPlaying,
                onSkipBackward: { audioPlayer.skipBackward() },
                onPlayPause: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.play()
                    }
                },
                onSkipForward: { audioPlayer.skipForward() }
            )
            
            PlaybackRateSelector(
                currentRate: audioPlayer.playbackRate,
                onRateSelected: { audioPlayer.setPlaybackRate($0) }
            )
        }
        .padding()
        .background(Color(.systemBackground))
    }
}

// MARK: - Audio Progress Ring

private struct AudioProgressRing: View {
    let progress: Double
    let isPlaying: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 120, height: 120)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.blue, lineWidth: 4)
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)
            
            Image(systemName: "waveform")
                .font(.system(size: 40))
                .foregroundStyle(.blue)
        }
    }
}

// MARK: - Audio Seek Bar

private struct AudioSeekBar: View {
    let currentTime: String
    let duration: String
    let progress: Double
    let onSeek: (Double) -> Void
    
    @State private var sliderValue: Double = 0
    
    var body: some View {
        HStack {
            Text(currentTime)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            
            Slider(value: Binding(
                get: { progress },
                set: { onSeek($0) }
            ))
            .tint(.blue)
            
            Text(duration)
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
        .padding(.horizontal)
    }
}

// MARK: - Audio Playback Controls

private struct AudioPlaybackControls: View {
    let isPlaying: Bool
    let onSkipBackward: () -> Void
    let onPlayPause: () -> Void
    let onSkipForward: () -> Void
    
    var body: some View {
        HStack(spacing: 32) {
            Button(action: onSkipBackward) {
                Image(systemName: "gobackward.15")
                    .font(.title2)
            }
            
            Button(action: onPlayPause) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
            }
            
            Button(action: onSkipForward) {
                Image(systemName: "goforward.15")
                    .font(.title2)
            }
        }
    }
}

// MARK: - Playback Rate Selector

private struct PlaybackRateSelector: View {
    let currentRate: Float
    let onRateSelected: (Float) -> Void
    
    private let rates: [Float] = [0.5, 1.0, 1.5, 2.0]
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(rates, id: \.self) { rate in
                PlaybackRateButton(
                    rate: rate,
                    isSelected: currentRate == rate,
                    onTap: { onRateSelected(rate) }
                )
            }
        }
    }
}

private struct PlaybackRateButton: View {
    let rate: Float
    let isSelected: Bool
    let onTap: () -> Void
    
    private var rateText: String {
        if rate == 1.0 || rate == 2.0 {
            return String(format: "%.0fx", rate)
        }
        return String(format: "%.1fx", rate)
    }
    
    var body: some View {
        Button(action: onTap) {
            Text(rateText)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    isSelected ? Color.blue.opacity(0.2) : Color(.systemGray6),
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AudioPlayerSection(audioPlayer: AudioPlayer())
}
