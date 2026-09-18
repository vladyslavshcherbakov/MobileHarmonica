import SwiftUI

struct HoleView: View {
    private static let cornerRadius: CGFloat = 8
    private static let drawHalfDimming = 0.55

    let state: HoleViewState

    var body: some View {
        RoundedRectangle(cornerRadius: Self.cornerRadius)
            .fill(breathHalves)
            .overlay { number }
    }

    private var breathHalves: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: blowHalf, location: 0),
                .init(color: blowHalf, location: 0.5),
                .init(color: drawHalf, location: 0.5),
                .init(color: drawHalf, location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var blowHalf: Color {
        state.isSounding ? .orange : Color(white: 0.22)
    }

    private var drawHalf: Color {
        blowHalf.opacity(Self.drawHalfDimming)
    }

    private var number: some View {
        Text(state.label)
            .font(.title2.weight(.semibold))
            .foregroundStyle(state.isSounding ? Color.black : Color(white: 0.55))
    }
}
