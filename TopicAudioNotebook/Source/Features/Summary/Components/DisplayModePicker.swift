import SwiftUI

struct DisplayModePicker: View {
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

#Preview {
    @Previewable @State var selection: SummaryDisplayMode = .points
    DisplayModePicker(selection: $selection)
        .padding()
}
