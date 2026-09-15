import SwiftUI

struct HoleView: View {
    private static let cornerRadius: CGFloat = 8

    let state: HoleViewState

    var body: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(state.isSounding ? Color.orange : Color(white: 0.16))
            .overlay {
                Text(state.label)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(state.isSounding ? Color.black : Color(white: 0.55))
            }
            .accessibilityElement()
            .accessibilityIdentifier("harmonica.hole.\(state.id)")
            .accessibilityLabel(state.label)
    }
}
