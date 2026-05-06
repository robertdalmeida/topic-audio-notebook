import SwiftUI

struct TranscriptionStatusBadge: View {
    let status: TranscriptionStatus
    let onRetry: () -> Void
    
    var body: some View {
        Button(action: onRetry) {
            HStack(spacing: 4) {
                if status == .inProgress {
                    ProgressView()
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: status.iconName)
                }
                Text(status.rawValue)
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor, in: Capsule())
            .foregroundStyle(foregroundColor)
        }
        .buttonStyle(.plain)
        .disabled(status != .failed)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending: return Color.orange.opacity(0.2)
        case .inProgress: return Color.blue.opacity(0.2)
        case .completed: return Color.green.opacity(0.2)
        case .failed: return Color.red.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        TranscriptionStatusBadge(status: .completed) { }
        TranscriptionStatusBadge(status: .pending) { }
        TranscriptionStatusBadge(status: .inProgress) { }
        TranscriptionStatusBadge(status: .failed) { }
    }
}
