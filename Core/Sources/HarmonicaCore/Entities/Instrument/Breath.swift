public enum Breath: Sendable {
    case blow
    case draw

    // MARK: - Public

    public init?(topmostOf positions: [PositionOnHarmonica]) {
        guard let topmost = PositionOnHarmonica.topmost(of: positions) else { return nil }

        self.init(at: topmost)
    }

    public var reversed: Breath {
        switch self {
        case .blow: .draw
        case .draw: .blow
        }
    }

    // MARK: - Private

    private init(at position: PositionOnHarmonica) {
        self = position.fractionAboveCentreLine >= 0 ? .blow : .draw
    }
}
