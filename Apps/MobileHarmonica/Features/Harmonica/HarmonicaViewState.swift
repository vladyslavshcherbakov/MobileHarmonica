enum HarmonicaViewState: Equatable {
    case preparingSound
    case ready([HoleViewState])
    case soundUnavailable(String)
}

// MARK: - HoleViewState

struct HoleViewState: Equatable, Identifiable {
    let id: Int
    let label: String
    let isSounding: Bool
}
