import SwiftUI

struct StatusBadge: View {
    let status: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(status)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.2), in: Capsule())
        .foregroundStyle(color)
    }
}

#Preview {
    VStack(spacing: 12) {
        StatusBadge(status: "Completed", icon: "checkmark.circle.fill", color: .green)
        StatusBadge(status: "Pending", icon: "clock", color: .orange)
        StatusBadge(status: "Failed", icon: "xmark.circle.fill", color: .red)
    }
}
