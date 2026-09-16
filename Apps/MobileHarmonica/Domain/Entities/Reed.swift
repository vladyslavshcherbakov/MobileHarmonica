struct Reed: Equatable {
    let hole: Hole
    let breath: Breath
}

// MARK: - Reed + PositionOnHarmonica

extension Reed {
    init?(at position: PositionOnHarmonica) {
        guard let hole = Hole(at: position) else { return nil }

        self.init(hole: hole, breath: Breath(at: position))
    }
}
