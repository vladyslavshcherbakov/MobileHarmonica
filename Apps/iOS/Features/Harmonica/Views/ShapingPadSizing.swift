import CoreGraphics

struct ShapingPadSizing {
    private static let naturalWidthFraction: CGFloat = 0.22
    private static let smallestScale: CGFloat = 0.45
    private static let largestScale: CGFloat = 2.0

    private let smallestSide: CGFloat
    private let largestSide: CGFloat

    // MARK: - Public

    init(in area: CGSize) {
        let naturalSide = min(area.height, area.width * Self.naturalWidthFraction)
        smallestSide = naturalSide * Self.smallestScale
        largestSide = min(area.height, naturalSide * Self.largestScale)
    }

    func side(for size: ShapingPadSize) -> CGFloat {
        smallestSide + (largestSide - smallestSide) * size.fraction
    }

    func size(afterPinching size: ShapingPadSize, by magnification: CGFloat) -> ShapingPadSize {
        let range = largestSide - smallestSide
        guard range > 0 else { return size }

        return ShapingPadSize(clamping: (side(for: size) * magnification - smallestSide) / range)
    }
}
