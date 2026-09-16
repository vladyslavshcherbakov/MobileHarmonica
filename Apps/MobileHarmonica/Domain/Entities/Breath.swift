enum Breath {
    case blow
    case draw
}

// MARK: - Breath + PositionOnHarmonica

extension Breath {
    init?(topmostOf positions: [PositionOnHarmonica]) {
        guard let topmost = positions.max(by: { $0.fractionAboveCentreLine < $1.fractionAboveCentreLine }) else {
            return nil
        }

        self.init(at: topmost)
    }

    private init(at position: PositionOnHarmonica) {
        self = position.fractionAboveCentreLine >= 0 ? .blow : .draw
    }
}
