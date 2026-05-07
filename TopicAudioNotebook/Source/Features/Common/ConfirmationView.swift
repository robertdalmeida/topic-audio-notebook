import SwiftUI

struct ConfirmationView: View {
    let title: String
    let message: String
    let icon: String
    let iconColor: Color
    let confirmButtonTitle: String
    let confirmButtonRole: ButtonRole?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    init(
        title: String,
        message: String,
        icon: String,
        iconColor: Color = .blue,
        confirmButtonTitle: String,
        confirmButtonRole: ButtonRole? = nil,
        onConfirm: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self.confirmButtonTitle = confirmButtonTitle
        self.confirmButtonRole = confirmButtonRole
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 80))
                .foregroundStyle(iconColor)
            
            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            
            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    Text(confirmButtonTitle)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(confirmButtonRole == .destructive ? Color.red : iconColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
}

struct ArchiveTopicConfirmationView: View {
    let topicName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationView(
            title: "Archive Topic?",
            message: "'\(topicName)' will be moved to the archived topics list. You can restore it anytime from there.",
            icon: "archivebox.fill",
            iconColor: .orange,
            confirmButtonTitle: "Archive Topic",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

struct DeleteTopicConfirmationView: View {
    let topicName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationView(
            title: "Delete Topic Permanently?",
            message: "'\(topicName)' and all its recordings will be permanently deleted. This action cannot be undone.",
            icon: "trash.fill",
            iconColor: .red,
            confirmButtonTitle: "Delete Permanently",
            confirmButtonRole: .destructive,
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

struct RestoreTopicConfirmationView: View {
    let topicName: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ConfirmationView(
            title: "Restore Topic?",
            message: "'\(topicName)' will be restored to your active topics list.",
            icon: "arrow.uturn.backward.circle.fill",
            iconColor: .blue,
            confirmButtonTitle: "Restore Topic",
            onConfirm: onConfirm,
            onCancel: onCancel
        )
    }
}

#Preview("Archive") {
    ArchiveTopicConfirmationView(
        topicName: "My Topic",
        onConfirm: {},
        onCancel: {}
    )
}

#Preview("Delete") {
    DeleteTopicConfirmationView(
        topicName: "My Topic",
        onConfirm: {},
        onCancel: {}
    )
}

#Preview("Restore") {
    RestoreTopicConfirmationView(
        topicName: "My Topic",
        onConfirm: {},
        onCancel: {}
    )
}
