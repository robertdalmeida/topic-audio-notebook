import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum SummaryDisplayMode: String, CaseIterable {
    case points = "Key Points"
    case longForm = "Full Summary"
    case fullContent = "All Content"
}

// MARK: - SummaryView

struct SummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SummaryViewModel
    
    init(topicId: UUID, repository: TopicRepository) {
        _viewModel = State(wrappedValue: SummaryViewModel(
            topicId: topicId,
            repository: repository
        ))
    }
    
    var body: some View {
        content
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task { await viewModel.onAppear() }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var content: some View {
        if let topic = viewModel.topic {
            SummaryContentView(
                topic: topic,
                viewModel: viewModel
            )
        } else {
            ContentUnavailableView("Topic Not Found", systemImage: "questionmark.circle")
        }
    }
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if viewModel.hasSummary {
            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: viewModel.shareContent) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}

// MARK: - SummaryContentView

private struct SummaryContentView: View {
    let topic: Topic
    @Bindable var viewModel: SummaryViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                TopicStatsHeader(topic: topic)
                
                DisplayModePicker(selection: $viewModel.displayMode)
                
                Divider()
                
                summaryContent
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var summaryContent: some View {
        switch viewModel.displayMode {
        case .points:
            KeyPointsSection(
                points: topic.consolidatedPoints,
                isGenerating: viewModel.isGeneratingKeyPoints,
                onGenerate: { Task { await viewModel.generateKeyPoints() } }
            )
        case .longForm:
            LongFormSection(
                summary: topic.consolidatedSummary,
                isGenerating: viewModel.isGeneratingSummary,
                onGenerate: { Task { await viewModel.generateFullSummary() } }
            )
        case .fullContent:
            FullContentSection(topic: topic)
        }
    }
}

// MARK: - Topic Stats Header

private struct TopicStatsHeader: View {
    let topic: Topic
    
    var body: some View {
        HStack(spacing: 12) {
            Label("\(topic.recordings.count)", systemImage: "waveform")
            Label("\(topic.notes.count)", systemImage: "doc.text")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

// MARK: - Display Mode Picker

private struct DisplayModePicker: View {
    @Binding var selection: SummaryDisplayMode
    
    var body: some View {
        Picker("Display Mode", selection: $selection) {
            ForEach(SummaryDisplayMode.allCases, id: \.self) { mode in
                Text(mode.rawValue).tag(mode)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Key Points Section

private struct KeyPointsSection: View {
    let points: [String]?
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Key Points")
                    .font(.headline)
                Spacer()
                
                if isGenerating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        if let points, !points.isEmpty {
                            CopyButton(points: points)
                        }
                        SummarizeButton(action: onGenerate)
                            .controlSize(.small)
                    }
                }
            }
            .padding(.bottom, 4)
            
            if let points, !points.isEmpty {
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    SummaryKeyPointRow(point: point)
                }
            } else if !isGenerating {
                ContentUnavailableView {
                    Label("No Key Points", systemImage: "list.bullet")
                } description: {
                    Text("Tap Generate to extract key points")
                }
                .frame(minHeight: 150)
            }
        }
        .textSelection(.enabled)
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct SummaryKeyPointRow: View {
    let point: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .font(.body)
                .foregroundStyle(.blue)
            
            Text(point)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

private struct CopyButton: View {
    let text: String

    init(points: [String]) {
        text = points.map { "• \($0)" }.joined(separator: "\n")

    }
    init(text: String) {
        self.text = text
    }

    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.subheadline)
        }
    }
    
    private func copyToClipboard() {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

// MARK: - Long Form Section

private struct LongFormSection: View {
    let summary: String?
    let isGenerating: Bool
    let onGenerate: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Full Summary")
                    .font(.headline)
                Spacer()
                
                if isGenerating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    HStack(spacing: 12) {
                        if let summary, !summary.isEmpty {
                            CopyButton(text: summary)
                        }
                        SummarizeButton(action: onGenerate)
                            .controlSize(.small)
                    }
                }
            }
            .padding(.bottom, 4)
            
            if let summary, !summary.isEmpty {
                MarkdownTextView(text: summary)
            } else if !isGenerating {
                ContentUnavailableView {
                    Label("No Summary", systemImage: "doc.richtext")
                } description: {
                    Text("Tap Generate to create a summary")
                }
                .frame(minHeight: 150)
            }
        }
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Full Content Section

private struct FullContentSection: View {
    let topic: Topic
    
    private var sortedItems: [ContentItem] {
        var items: [ContentItem] = []
        
        for recording in topic.activeRecordings {
            items.append(ContentItem(
                id: recording.id,
                type: .recording,
                title: recording.title,
                content: recording.transcript,
                date: recording.createdAt,
                duration: recording.duration
            ))
        }
        
        for note in topic.activeNotes {
            items.append(ContentItem(
                id: note.id,
                type: .note,
                title: nil,
                content: note.content,
                date: note.createdAt,
                duration: nil
            ))
        }
        
        return items.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("All Content")
                    .font(.headline)
                Spacer()
                
                if !sortedItems.isEmpty {
                    CopyButton(text: formattedFullContent)
                }
            }
            .padding(.bottom, 4)
            
            if sortedItems.isEmpty {
                ContentUnavailableView {
                    Label("No Content", systemImage: "doc.text")
                } description: {
                    Text("Add recordings or notes to see content here")
                }
                .frame(minHeight: 150)
            } else {
                ForEach(sortedItems) { item in
                    ContentItemView(item: item)
                }
            }
        }
        .textSelection(.enabled)
        .padding()
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
    }
    
    var formattedFullContent: String {
        var content = "# \(topic.name) - All Content\n\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for item in sortedItems {
            let dateString = dateFormatter.string(from: item.date)
            
            switch item.type {
            case .recording:
                content += "## 🎙️ Recording: \(item.title ?? "Untitled")\n"
                content += "📅 \(dateString)"
                if let duration = item.duration {
                    let minutes = Int(duration) / 60
                    let seconds = Int(duration) % 60
                    content += " • ⏱️ \(String(format: "%d:%02d", minutes, seconds))"
                }
                content += "\n\n"
                if let transcript = item.content, !transcript.isEmpty {
                    content += "### Transcription\n\(transcript)\n\n"
                } else {
                    content += "*No transcription available*\n\n"
                }
            case .note:
                content += "## 📝 Note\n"
                content += "📅 \(dateString)\n\n"
                if let noteContent = item.content, !noteContent.isEmpty {
                    content += "\(noteContent)\n\n"
                }
            }
            
            content += "---\n\n"
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct ContentItem: Identifiable {
    let id: UUID
    let type: ContentItemType
    let title: String?
    let content: String?
    let date: Date
    let duration: TimeInterval?
}

private enum ContentItemType {
    case recording
    case note
}

private struct ContentItemView: View {
    let item: ContentItem
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: item.date)
    }
    
    private var formattedDuration: String? {
        guard let duration = item.duration else { return nil }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                Image(systemName: item.type == .recording ? "waveform" : "doc.text")
                    .foregroundStyle(item.type == .recording ? .blue : .orange)
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 4) {
                    if item.type == .recording {
                        Text(item.title ?? "Untitled Recording")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    } else {
                        Text("Note")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 8) {
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if let duration = formattedDuration {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(duration)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            if let content = item.content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .padding(.leading, 28)
            } else if item.type == .recording {
                Text("No transcription available")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .italic()
                    .padding(.leading, 28)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(Color(.systemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdown(), id: \.id) { block in
                switch block.type {
                case .heading1:
                    Text(block.content)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.top, 8)
                case .heading2:
                    Text(block.content)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding(.top, 6)
                case .heading3:
                    Text(block.content)
                        .font(.title3)
                        .fontWeight(.medium)
                        .padding(.top, 4)
                case .bullet:
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(block.content)
                    }
                case .paragraph:
                    Text(block.content)
                case .divider:
                    Divider()
                        .padding(.vertical, 4)
                }
            }
        }
        .textSelection(.enabled)
    }
    
    private func parseMarkdown() -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        let lines = text.components(separatedBy: "\n")
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                continue
            } else if trimmed.hasPrefix("### ") {
                blocks.append(MarkdownBlock(type: .heading3, content: String(trimmed.dropFirst(4))))
            } else if trimmed.hasPrefix("## ") {
                blocks.append(MarkdownBlock(type: .heading2, content: String(trimmed.dropFirst(3))))
            } else if trimmed.hasPrefix("# ") {
                blocks.append(MarkdownBlock(type: .heading1, content: String(trimmed.dropFirst(2))))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(MarkdownBlock(type: .bullet, content: String(trimmed.dropFirst(2))))
            } else if trimmed == "---" || trimmed == "***" {
                blocks.append(MarkdownBlock(type: .divider, content: ""))
            } else {
                blocks.append(MarkdownBlock(type: .paragraph, content: trimmed))
            }
        }
        
        return blocks
    }
}

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: MarkdownBlockType
    let content: String
}

enum MarkdownBlockType {
    case heading1, heading2, heading3, bullet, paragraph, divider
}

#Preview {
    let repository = TopicRepository()
    let topic = Topic(
        name: "Sample Topic",
        consolidatedSummary: """
        # Executive Summary
        
        This is a consolidated summary of multiple recordings about the topic.
        
        ## Key Themes
        
        - First important point
        - Second important point
        - Third important point
        
        ## Main Points
        
        ### Theme 1
        
        Details about the first theme discussed across recordings.
        
        ### Theme 2
        
        Details about the second theme.
        
        ---
        
        *Generated from 3 recordings*
        """,
        consolidatedPoints: ["First key point", "Second key point", "Third key point"]
    )
    return SummaryView(topicId: topic.id, repository: repository)
}
