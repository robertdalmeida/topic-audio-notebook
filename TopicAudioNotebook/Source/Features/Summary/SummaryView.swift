import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum SummaryDisplayMode: String, CaseIterable {
    case points = "Key Points"
    case longForm = "Full Summary"
}

// MARK: - SummaryView

struct SummaryView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: SummaryViewModel
    
    init(topicId: UUID, repository: TopicRepository, onRegenerate: (() async -> Void)? = nil) {
        _viewModel = State(wrappedValue: SummaryViewModel(
            topicId: topicId,
            repository: repository,
            regenerateAction: onRegenerate
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
                HStack {
                    TopicStatsHeader(topic: topic)
                    Spacer()
                    RegenerateActionSection(viewModel: viewModel)
                }
                
                if viewModel.hasSummary {
                    DisplayModePicker(selection: $viewModel.displayMode)
                }
                
                Divider()
                
                summaryBody
            }
            .padding()
        }
    }
    
    @ViewBuilder
    private var summaryBody: some View {
        switch viewModel.viewState {
        case .loading, .ready, .error:
            if viewModel.hasSummary {
                summaryContent
            } else {
                NoSummaryView()
            }
        case .regenerating:
            LoadingStateView(message: "Regenerating summary...", subtitle: "This may take a moment")
        }
    }
    
    @ViewBuilder
    private var summaryContent: some View {
        if viewModel.displayMode == .points {
            KeyPointsSection(points: topic.consolidatedPoints)
        } else {
            LongFormSection(summary: topic.consolidatedSummary)
        }
    }
}

// MARK: - Regenerate Action Section

private struct RegenerateActionSection: View {
    @Bindable var viewModel: SummaryViewModel
    
    var body: some View {
        SummarizeButton(
            title: "Regenerate",
            icon: "arrow.clockwise",
            action: {
                Task { await viewModel.regenerateSummary() }
            }
        )
        .controlSize(.small)
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

// MARK: - No Summary View

private struct NoSummaryView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Summary Yet", systemImage: "doc.text.magnifyingglass")
        } description: {
            Text("Tap the regenerate button to generate a summary from your recordings")
        }
        .padding(.vertical, 20)
    }
}

// MARK: - Loading State View

private struct LoadingStateView: View {
    let message: String
    var subtitle: String?
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.headline)
            
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Key Points Section

private struct KeyPointsSection: View {
    let points: [String]?
    
    var body: some View {
        if let points, !points.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Key Points")
                        .font(.headline)
                    Spacer()
                    CopyButton(points: points)
                }
                .padding(.bottom, 4)
                
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
                    SummaryKeyPointRow(point: point)
                }
            }
            .textSelection(.enabled)
            .padding()
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
        } else {
            ContentUnavailableView {
                Label("No Key Points", systemImage: "list.bullet")
            } description: {
                Text("Key points will appear here after consolidation")
            }
        }
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
    let points: [String]
    
    var body: some View {
        Button {
            copyToClipboard()
        } label: {
            Image(systemName: "doc.on.doc")
                .font(.subheadline)
        }
    }
    
    private func copyToClipboard() {
        let text = points.map { "• \($0)" }.joined(separator: "\n")
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
    
    var body: some View {
        if let summary {
            MarkdownTextView(text: summary)
        } else {
            ContentUnavailableView {
                Label("No Summary", systemImage: "doc.richtext")
            } description: {
                Text("Generate a summary by tapping Regenerate")
            }
        }
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
