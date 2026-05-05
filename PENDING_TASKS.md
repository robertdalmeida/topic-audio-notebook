# Pending Tasks & Feature Roadmap

## Phase 1: Core Enhancements (High Priority)

### Audio Playback
- [ ] Add audio player to play back recordings
- [ ] Implement playback controls (play/pause, seek, speed)
- [ ] Show waveform visualization during playback
- [ ] Add background audio playback support

### Transcription Improvements
- [ ] Support multiple languages for transcription
- [ ] Add manual transcription editing
- [ ] Implement real-time transcription during recording
- [ ] Add transcription confidence indicators
- [ ] Support offline transcription with on-device models

### Data Persistence
- [ ] Migrate from UserDefaults to Core Data or SwiftData
- [ ] Add iCloud sync for topics and recordings
- [ ] Implement data export (JSON, CSV)
- [ ] Add backup/restore functionality

## Phase 2: AI & Intelligence (Medium Priority)

### Enhanced AI Features
- [ ] Support multiple AI providers (Claude, Gemini, local LLMs)
- [ ] Add custom summarization prompts
- [ ] Implement key point extraction
- [ ] Add action item detection
- [ ] Generate topic tags automatically
- [ ] Support incremental summary updates

### Search & Discovery
- [ ] Full-text search across all transcripts
- [ ] Search within specific topics
- [ ] Filter recordings by date, duration, status
- [ ] Add semantic search using embeddings

## Phase 3: User Experience (Medium Priority)

### UI/UX Improvements
- [ ] Add dark mode optimizations
- [ ] Implement drag-and-drop for organizing recordings
- [ ] Add swipe actions for quick operations
- [ ] Create iPad-optimized layout
- [ ] Add haptic feedback
- [ ] Implement pull-to-refresh

### Recording Enhancements
- [ ] Add pause/resume during recording
- [ ] Implement recording bookmarks/markers
- [ ] Add noise reduction options
- [ ] Support external microphones
- [ ] Add recording quality settings

### Topic Management
- [ ] Add topic templates
- [ ] Implement topic archiving
- [ ] Add topic sharing/collaboration
- [ ] Support nested topics (subtopics)
- [ ] Add topic statistics dashboard

## Phase 4: Integration & Export (Lower Priority)

### Integrations
- [ ] Share to Notes, Reminders
- [ ] Export to Notion, Obsidian
- [ ] Calendar integration for meeting recordings
- [ ] Shortcuts app support
- [ ] Widget for quick recording

### Export Options
- [ ] Export summary as PDF
- [ ] Export audio with transcript (SRT/VTT)
- [ ] Batch export functionality
- [ ] Email sharing with formatting

## Phase 5: Advanced Features (Future)

### Collaboration
- [ ] Share topics with other users
- [ ] Real-time collaborative editing
- [ ] Comments on recordings/transcripts
- [ ] Team workspaces

### Analytics
- [ ] Recording statistics (total time, frequency)
- [ ] Topic activity trends
- [ ] Word frequency analysis
- [ ] Speaking pace analysis

### Accessibility
- [ ] VoiceOver optimization
- [ ] Dynamic Type support
- [ ] High contrast mode
- [ ] Reduce motion support

## Technical Debt

- [ ] Add unit tests for models and services
- [ ] Add UI tests for critical flows
- [ ] Implement proper error handling throughout
- [ ] Add logging and crash reporting
- [ ] Optimize memory usage for large recordings
- [ ] Add proper loading states and skeleton views
- [ ] Implement retry logic for network failures

## Known Issues

- [ ] Transcription may fail for very long recordings (>1 hour)
- [ ] Audio visualizer animation can be CPU-intensive
- [ ] Need to handle app backgrounding during recording

---

*Last updated: Initial version*
