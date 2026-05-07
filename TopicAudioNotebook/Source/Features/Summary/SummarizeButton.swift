import SwiftUI

struct SummarizeButton: View {
    let title: String
    let icon: String
    let isEnabled: Bool
    let style: Style
    let action: () -> Void
    
    @State private var stateManager = SummarizationStateManager.shared
    
    enum Style {
        case capsule
        case rounded
    }
    
    init(
        title: String = "",
        icon: String = "sparkles",
        isEnabled: Bool = true,
        style: Style = .capsule,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.style = style
        self.action = action
    }
    
    var body: some View {
        if stateManager.isSummarizationEnabled {
            VStack(spacing: 8) {
                mainContent
                statusIndicator
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch stateManager.modelState {
        case .loading(let progress):
            loadingView(progress: progress)
        case .idle, .ready, .failed:
            if stateManager.isSummarizing {
                summarizingView
            } else {
                actionButton
            }
        }
    }
    
    private func loadingView(progress: Double) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Loading model...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 120)
            
            Text("\(Int(progress * 100))%")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var summarizingView: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Generating...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private var actionButton: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.subheadline)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(style == .capsule ? .capsule : .roundedRectangle(radius: 8))
        .disabled(!isEnabled || !stateManager.canSummarize)
    }
    
    @ViewBuilder
    private var statusIndicator: some View {
        if case .failed(let message) = stateManager.modelState {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }
            .lineLimit(2)
            .multilineTextAlignment(.center)
        }
    }
}

#Preview("Idle State") {
    SummarizeButton(action: {})
}

#Preview("Rounded Style") {
    SummarizeButton(title: "Generate Topic Summary", style: .rounded, action: {})
}
