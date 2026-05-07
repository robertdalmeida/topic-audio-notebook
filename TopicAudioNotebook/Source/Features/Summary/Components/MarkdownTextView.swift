import SwiftUI

struct MarkdownTextView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(parseMarkdown(), id: \.id) { block in
                MarkdownBlockView(block: block)
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

// MARK: - Block View

private struct MarkdownBlockView: View {
    let block: MarkdownBlock
    
    var body: some View {
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

// MARK: - Models

struct MarkdownBlock: Identifiable {
    let id = UUID()
    let type: MarkdownBlockType
    let content: String
}

enum MarkdownBlockType {
    case heading1, heading2, heading3, bullet, paragraph, divider
}

// MARK: - Previews

#Preview {
    ScrollView {
        MarkdownTextView(text: """
        # Main Title
        
        This is a paragraph of text explaining the content.
        
        ## Section Header
        
        - First bullet point
        - Second bullet point
        - Third bullet point
        
        ### Subsection
        
        More detailed content here.
        
        ---
        
        Final notes and conclusion.
        """)
        .padding()
    }
}
