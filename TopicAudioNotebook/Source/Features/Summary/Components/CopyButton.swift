import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

struct CopyButton: View {
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

#Preview {
    HStack(spacing: 20) {
        CopyButton(text: "Sample text to copy")
        CopyButton(points: ["Point 1", "Point 2", "Point 3"])
    }
    .padding()
}
