# Topic Audio Notebook

A SwiftUI iOS app for organizing audio recordings by topic with automatic transcription and AI-powered summary consolidation.

## Features

### Core Functionality
- **Topic Organization**: Create and manage topics/folders to organize related recordings
- **Audio Recording**: Record audio clips directly within the app with visual feedback
- **Automatic Transcription**: Uses Apple's Speech Recognition to transcribe recordings
- **AI Consolidation**: Synthesize multiple transcripts into a cohesive summary using OpenAI

### User Interface
- Modern iOS design with clean, intuitive navigation
- Topic dashboard with status indicators
- Real-time transcription status tracking
- Audio level visualization during recording
- Markdown-formatted summary display

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository
2. Open `TopicAudioNotebook.xcodeproj` in Xcode
3. Select your development team in Signing & Capabilities
4. Build and run on a device (microphone required for recording)

### Optional: OpenAI API Key

For AI-powered summary consolidation:
1. Get an API key from [OpenAI Platform](https://platform.openai.com/api-keys)
2. Open the app's Settings
3. Enter your API key

Without an API key, the app will generate a basic summary combining all transcripts.

### Optional: MLX Phi-3.5 Support (macOS only)

For on-device AI summarization using Phi-3.5 via MLX:

1. Add the MLX-Swift Examples package to your project:
   - In Xcode, go to File → Add Package Dependencies
   - Enter: `https://github.com/ml-explore/mlx-swift-examples`
   - Add the `MLXLLM` and `MLXLMCommon` products to your target

2. The Phi-3.5 option will automatically appear in Settings when MLX is available

**Note**: MLX requires macOS with Apple Silicon. The model (~2GB) downloads on first use.

### Optional: Apple Intelligence (iOS 26+)

On devices running iOS 26 or later with Apple Intelligence enabled, the "Apple Intelligence" summarization option will automatically appear in Settings.

## Architecture

```
TopicAudioNotebook/
├── TopicAudioNotebookApp.swift    # App entry point
├── Models/
│   ├── Topic.swift                # Topic data model
│   └── Recording.swift            # Recording data model
├── Views/
│   ├── ContentView.swift          # Main dashboard
│   ├── AddTopicView.swift         # Topic creation
│   ├── TopicDetailView.swift      # Topic details & recordings
│   ├── RecordingView.swift        # Audio recording interface
│   ├── TranscriptView.swift       # Individual transcript view
│   ├── SummaryView.swift          # Consolidated summary view
│   └── SettingsView.swift         # App settings
└── Services/
    ├── TopicStore.swift           # Data persistence & management
    ├── AudioRecorder.swift        # Audio recording service
    ├── TranscriptionService.swift # Speech recognition
    └── AIService.swift            # OpenAI integration
```

## Permissions

The app requires:
- **Microphone**: For audio recording
- **Speech Recognition**: For transcription

## License

MIT License
