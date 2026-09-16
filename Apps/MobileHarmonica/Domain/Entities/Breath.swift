enum Breath {
    case blow
    case draw

    var reversed: Breath {
        switch self {
        case .blow: .draw
        case .draw: .blow
        }
    }
}

// MARK: - Breath + PositionOnHarmonica

extension Breath {
    init?(topmostOf positions: [PositionOnHarmonica]) {
        guard let topmost = PositionOnHarmonica.topmost(of: positions) else { return nil }

        self.init(at: topmost)
    }

    private init(at position: PositionOnHarmonica) {
        self = position.fractionAboveCentreLine >= 0 ? .blow : .draw
    }
}
