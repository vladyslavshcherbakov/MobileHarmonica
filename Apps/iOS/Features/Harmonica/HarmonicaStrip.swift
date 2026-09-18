import SwiftUI

@MainActor
struct HarmonicaStrip: View {
    static let holeSpacing: CGFloat = 6

    private static let noteRowHeight: CGFloat = 30

    let holes: [HoleViewState]
    let fingerMarks: FingerMarksViewState
    @ObservedObject var viewModel: HarmonicaViewModel
    @State private var touches: [FingerTouch] = []

    // MARK: - Public

    var body: some View {
        VStack(spacing: 0) {
            noteRow
            GeometryReader { geometry in
                plates
                    .overlay {
                        FingerCircles(marks: Self.marks(at: touches, across: geometry.size, style: fingerMarks))
                    }
                    .overlay { touchArea(across: geometry.size) }
            }
        }
    }

    // MARK: - Private

    private static func position(of touch: FingerTouch, across size: CGSize) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: Double(touch.location.x / size.width),
            fractionAboveCentreLine: Double((size.height / 2 - touch.location.y) / size.height),
            fractionCoveredEitherSide: Double(touch.radius / size.width)
        )
    }

    private static func marks(
        at touches: [FingerTouch],
        across size: CGSize,
        style: FingerMarksViewState
    ) -> [FingerMark] {
        let positions = touches.map { position(of: $0, across: size) }
        let deciding = PositionOnHarmonica.topmost(of: positions.filter(\.isOnTheHarmonica))

        return positions.indices
            .filter { isDrawn(positions[$0], deciding: deciding, style: style) }
            .map { mark(index: $0, at: touches[$0], decidesBreath: positions[$0] == deciding, style: style) }
    }

    private static func isDrawn(
        _ position: PositionOnHarmonica,
        deciding: PositionOnHarmonica?,
        style: FingerMarksViewState
    ) -> Bool {
        style.onlyTheDecidingFinger ? position == deciding : position.isOnTheHarmonica
    }

    private static func mark(
        index: Int,
        at touch: FingerTouch,
        decidesBreath: Bool,
        style: FingerMarksViewState
    ) -> FingerMark {
        FingerMark(
            id: index,
            location: touch.location,
            diameter: style.atTheContactWidth ? 2 * touch.radius : FingerCircles.diameter,
            decidesBreath: decidesBreath
        )
    }

    private var noteRow: some View {
        HStack(spacing: Self.holeSpacing) {
            ForEach(holes) { hole in
                soundingNote(hole)
            }
        }
        .frame(height: Self.noteRowHeight)
    }

    private func soundingNote(_ hole: HoleViewState) -> some View {
        VStack(spacing: 0) {
            Text(hole.note)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            Text(hole.effect)
                .font(.caption2)
                .foregroundStyle(Color(white: 0.5))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity)
    }

    private var plates: some View {
        HStack(spacing: Self.holeSpacing) {
            ForEach(holes) { hole in
                HoleView(state: hole)
            }
        }
    }

    private func touchArea(across size: CGSize) -> some View {
        TouchArea { touches in
            self.touches = touches
            viewModel.play(at: touches.map { Self.position(of: $0, across: size) })
        }
    }
}
