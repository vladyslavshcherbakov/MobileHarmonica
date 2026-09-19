public enum Breath {
    case blow
    case draw

    public var reversed: Breath {
        switch self {
        case .blow: .draw
        case .draw: .blow
        }
    }
}

// MARK: - PositionOnHarmonica + Breath

public extension PositionOnHarmonica {
    private static let slackAcrossTheBoundary = 0.06

    var isCrossingTheBreathBoundary: Bool {
        abs(fractionAboveCentreLine) < Self.slackAcrossTheBoundary
    }
}

// MARK: - Breath + PositionOnHarmonica

public extension Breath {
    init?(topmostOf positions: [PositionOnHarmonica]) {
        guard let topmost = PositionOnHarmonica.topmost(of: positions) else { return nil }

        self.init(at: topmost)
    }

    private init(at position: PositionOnHarmonica) {
        self = position.fractionAboveCentreLine >= 0 ? .blow : .draw
    }
}
