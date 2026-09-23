import CoreGraphics
import HarmonicaCore

struct StripTouchMapper {
    private let touches: [FingerTouch]
    private let size: CGSize

    // MARK: - Public

    init(_ touches: [FingerTouch], across size: CGSize) {
        self.touches = touches
        self.size = size
    }

    var positions: [PositionOnHarmonica] {
        touches.map(position(of:))
    }

    func marks(drawn style: HarmonicaViewState.FingerMarks) -> [FingerMark] {
        let fingerPositions = positions
        let deciding = PositionOnHarmonica.topmost(of: fingerPositions.filter(\.isOnTheHarmonica))

        return fingerPositions.indices
            .filter { isDrawn(fingerPositions[$0], deciding: deciding, style: style) }
            .map { mark(index: $0, isTheDecidingFinger: fingerPositions[$0] == deciding, style: style) }
    }

    // MARK: - Private

    private func position(of touch: FingerTouch) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: Double(touch.location.x / size.width),
            fractionAboveCentreLine: Double((size.height / 2 - touch.location.y) / size.height),
            fractionCoveredEitherSide: Double(touch.radius / size.width)
        )
    }

    private func isDrawn(
        _ position: PositionOnHarmonica,
        deciding: PositionOnHarmonica?,
        style: HarmonicaViewState.FingerMarks
    ) -> Bool {
        style.drawsOnlyTheDecidingFinger ? position == deciding : position.isOnTheHarmonica
    }

    private func mark(index: Int, isTheDecidingFinger: Bool, style: HarmonicaViewState.FingerMarks) -> FingerMark {
        FingerMark(
            id: index,
            location: touches[index].location,
            diameter: style.isDrawnAtTheContactWidth ? 2 * touches[index].radius : FingerMark.restingDiameter,
            isTheDecidingFinger: isTheDecidingFinger
        )
    }
}
