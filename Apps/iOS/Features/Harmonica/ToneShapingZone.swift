import SwiftUI

struct ToneShapingZone: View {
    private static let cornerRadius: CGFloat = 12

    let state: ToneShapingViewState
    let pinched: (CGFloat) -> Void
    @ObservedObject var viewModel: HarmonicaViewModel
    @State private var touches: [FingerTouch] = []

    // MARK: - Public

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: Self.cornerRadius)
                .fill(Color(white: 0.13))
                .overlay(alignment: .leading) { pitchLabels }
                .overlay(alignment: .bottomTrailing) { vibratoLabel }
                .overlay { FingerCircles(marks: Self.marks(at: touches)) }
                .overlay { touchArea(across: geometry.size) }
        }
    }

    // MARK: - Private

    private static func marks(at touches: [FingerTouch]) -> [FingerMark] {
        let leading = topmost(of: touches)

        return touches.indices.map { index in
            FingerMark(
                id: index,
                location: touches[index].location,
                diameter: FingerCircles.diameter,
                decidesBreath: touches[index].location == leading
            )
        }
    }

    private static func topmost(of touches: [FingerTouch]) -> CGPoint? {
        touches.map(\.location).min { $0.y < $1.y }
    }

    private static func shade(isAvailable: Bool) -> Color {
        isAvailable ? Color(white: 0.55) : Color(white: 0.3)
    }

    private var pitchLabels: some View {
        VStack(alignment: .leading) {
            Text(state.overbendLabel)
                .foregroundStyle(Self.shade(isAvailable: state.overbendIsAvailable))
            Spacer()
            Text(state.bendLabel)
                .foregroundStyle(Self.shade(isAvailable: state.bendIsAvailable))
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
                shapeTone(from: touches, across: size)
            },
            pinched: pinched
        )
    }

    private func shapeTone(from touches: [FingerTouch], across size: CGSize) {
        guard let leading = Self.topmost(of: touches) else {
            viewModel.stopShapingTone()
            return
        }

        viewModel.shapeTone(
            pitch: 1 - 2 * Double(leading.y / size.height),
            vibrato: Double(leading.x / size.width)
        )
    }
}
