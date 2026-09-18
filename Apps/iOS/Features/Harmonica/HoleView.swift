import SwiftUI

struct HoleView: View {
    private static let cornerRadius: CGFloat = 8
    private static let bottomHalfDimming = 0.55

    let state: HoleViewState

    var body: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(breathHalves)
            .overlay { number }
    }

    private var breathHalves: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: topHalf, location: 0),
                .init(color: topHalf, location: 0.5),
                .init(color: bottomHalf, location: 0.5),
                .init(color: bottomHalf, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topHalf: Color {
        shade(lit: state.lit == .top)
    }

    private var bottomHalf: Color {
        shade(lit: state.lit == .bottom).opacity(Self.bottomHalfDimming)
    }

    private func shade(lit: Bool) -> Color {
        lit ? .orange : Color(white: 0.22)
    }

    private var number: some View {
        Text(state.label)
            .font(.title2.weight(.semibold))
            .foregroundStyle(state.lit == nil ? Color(white: 0.55) : Color.black)
    }
}
