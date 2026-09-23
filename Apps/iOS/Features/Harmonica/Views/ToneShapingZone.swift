import SwiftUI

@MainActor
struct ToneShapingZone: View {
    private static let cornerRadius: CGFloat = 12

    let state: HarmonicaViewState.ToneShaping
    let pinched: @MainActor (CGFloat) -> Void
    let pinchEnded: @MainActor () -> Void
    @ObservedObject var viewModel: HarmonicaViewModel
    @State private var touches: [FingerTouch] = []

    // MARK: - Public

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(Color(white: 0.13))
                .overlay(alignment: .leading) { pitchLabels }
                .overlay(alignment: .bottomTrailing) { vibratoLabel }
                .overlay { FingerCircles(marks: viewModel.marksOnTheSquare(for: touches, across: geometry.size)) }
                .overlay { touchArea(across: geometry.size) }
        }
    }

    // MARK: - Private

    private static func shade(isAvailable: Bool) -> Color {
        isAvailable ? Color(white: 0.55) : Color(white: 0.3)
    }

    private var pitchLabels: some View {
        VStack(alignment: .leading) {
            Text(state.overbendLabel)
                .foregroundStyle(Self.shade(isAvailable: state.isOverbendAvailable))
            Spacer()
            Text(state.bendLabel)
                .foregroundStyle(Self.shade(isAvailable: state.isBendAvailable))
        }
        .font(.caption)
        .padding(8)
    }

    private var vibratoLabel: some View {
        Text(state.vibratoLabel)
            .font(.caption)
            .foregroundStyle(Self.shade(isAvailable: true))
            .padding(8)
    }

    private func touchArea(across size: CGSize) -> some View {
        TouchArea(
            touchesChanged: { touches in
                self.touches = touches
                viewModel.shapeTone(with: touches, across: size)
            },
            pinched: pinched,
            pinchEnded: pinchEnded
        )
    }
}
