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

struct SummaryView: View {
    @Environment(\.dismiss) private var dismiss
    let topic: Topic
    let onRegenerate: (() -> Void)?
    
    @State private var displayMode: SummaryDisplayMode = .points
    
    init(topic: Topic, onRegenerate: (() -> Void)? = nil) {
        self.topic = topic
        self.onRegenerate = onRegenerate
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Label("\(topic.recordings.count) recordings", systemImage: "waveform")
                        Spacer()
                        Label("\(topic.transcribedRecordingsCount) transcribed", systemImage: "doc.text")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if topic.consolidatedSummary != nil || topic.consolidatedPoints != nil {
                        Picker("Display Mode", selection: $displayMode) {
                            ForEach(SummaryDisplayMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Divider()
                    
                    if displayMode == .points {
                        pointsView
                    } else {
                        longFormView
                    }
                }
                .padding()
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if topic.consolidatedSummary != nil {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            ShareLink(item: shareContent) {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            
                            if let onRegenerate {
                                Divider()
                                
                                Button(action: {
                                    onRegenerate()
                                    dismiss()
                                }) {
                                    Label("Regenerate Summary", systemImage: "arrow.clockwise")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var pointsView: some View {
        if let points = topic.consolidatedPoints, !points.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Key Points")
                        .font(.headline)
                    Spacer()
                    Button {
                        copyPointsToClipboard(points)
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.subheadline)
                    }
                }
                .padding(.bottom, 4)
                
                ForEach(Array(points.enumerated()), id: \.offset) { _, point in
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
    
    private func copyPointsToClipboard(_ points: [String]) {
        let text = points.map { "• \($0)" }.joined(separator: "\n")
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
    
    @ViewBuilder
    private var longFormView: some View {
        if let summary = topic.consolidatedSummary {
            MarkdownTextView(text: summary)
        } else {
            ContentUnavailableView {
                Label("No Summary", systemImage: "doc.richtext")
            } description: {
                Text("Generate a summary by tapping Consolidate")
            }
        }
    }
    
    private var shareContent: String {
        var content = "# \(topic.name) - Summary\n\n"
        
        if let points = topic.consolidatedPoints, !points.isEmpty {
            content += "## Key Points\n\n"
            for (index, point) in points.enumerated() {
                content += "\(index + 1). \(point)\n"
            }
            content += "\n"
        }
        
        if let summary = topic.consolidatedSummary {
            content += "## Full Summary\n\n\(summary)"
        }
        
        return content
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
    SummaryView(topic: Topic(
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
        """
    ))
}
