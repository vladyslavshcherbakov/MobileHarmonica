import SwiftUI

@MainActor
struct ShapingPad: View {
    private static let cornerRadius: CGFloat = 12

    let state: HarmonicaViewState.ShapingPad
    let pinchArea: CGSize
    @ObservedObject var viewModel: HarmonicaViewModel
    @State private var touches: [FingerTouch] = []

    // MARK: - Public

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(Color(white: 0.13))
                .overlay(alignment: .topLeading) { pitchLabel }
                .overlay(alignment: .bottomTrailing) { vibratoLabel }
                .overlay { FingerCircles(marks: viewModel.marksOnTheShapingPad(for: touches, across: geometry.size)) }
                .overlay { touchArea(across: geometry.size) }
        }
    }

    // MARK: - Private

    private static func shade(isAvailable: Bool) -> Color {
        isAvailable ? Color(white: 0.55) : Color(white: 0.3)
    }

    private var pitchLabel: some View {
        Text(state.pitchLabel)
            .font(.caption)
            .foregroundStyle(Self.shade(isAvailable: state.isPitchShapingAvailable))
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
                viewModel.send(.shapingPadTouched(touches, across: size))
            },
            pinched: { magnification in
                viewModel.send(.shapingPadPinched(by: magnification, within: pinchArea))
            }
        )
    }
}
