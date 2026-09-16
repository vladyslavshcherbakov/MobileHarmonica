enum Breath {
    case blow
    case draw
}

// MARK: - Breath + PositionOnHarmonica

extension Breath {
    init(at position: PositionOnHarmonica) {
        self = position.fractionAboveCentreLine >= 0 ? .blow : .draw
    }
}
