import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    HStack(spacing: 20) {
        StatCard(title: "Recordings", value: "5", icon: "waveform", color: .blue)
        StatCard(title: "Transcribed", value: "3", icon: "doc.text", color: .green)
        StatCard(title: "Duration", value: "12:30", icon: "clock", color: .orange)
    }
    .padding()
}
