import SwiftUI

struct AddTopicView: View {
    @StateObject var viewModel: AddTopicViewModel
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Topic Name", text: $viewModel.name)
                    TextField("Description (optional)", text: $viewModel.description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                        ForEach(TopicColor.allCases, id: \.self) { color in
                            ColorButton(color: color, isSelected: viewModel.selectedColor == color) {
                                viewModel.selectColor(color)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: viewModel.cancel)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create", action: viewModel.createTopic)
                        .disabled(!viewModel.canCreate)
                }
            }
        }
    }
}

struct ColorButton: View {
    let color: TopicColor
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(swiftUIColor)
                .frame(width: 44, height: 44)
                .overlay {
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.white)
                            .fontWeight(.bold)
                    }
                }
                .overlay {
                    Circle()
                        .strokeBorder(isSelected ? swiftUIColor : .clear, lineWidth: 3)
                        .frame(width: 52, height: 52)
                }
        }
        .buttonStyle(.plain)
    }
    
    private var swiftUIColor: Color {
        switch color {
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .pink: return .pink
        case .teal: return .teal
        case .indigo: return .indigo
        }
    }
}

#Preview {
    let repository = TopicRepository()
    return AddTopicView(viewModel: AddTopicViewModel(repository: repository, onDismiss: {}))
        .environmentObject(repository)
}
