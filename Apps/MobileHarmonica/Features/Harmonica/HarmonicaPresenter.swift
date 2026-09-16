import Foundation

struct HarmonicaPresenter {
    private static let soundUnavailableText = "Sound is unavailable."

    private let holeLabels: [String]

    // MARK: - Public

    init(locale: Locale) {
        holeLabels = Hole.allCases.map { $0.number.formatted(.number.locale(locale)) }
    }

    func present(soundingHole: Hole?, key: HarmonicaKey) -> HarmonicaViewState {
        .ready(PlayableHarmonica(holes: holes(soundingHole: soundingHole), key: keyState(key)))
    }

    func presentSoundUnavailable() -> HarmonicaViewState {
        .soundUnavailable(Self.soundUnavailableText)
    }

    // MARK: - Private

    private func holes(soundingHole: Hole?) -> [HoleViewState] {
        zip(Hole.allCases, holeLabels).map { hole, label in
            HoleViewState(id: hole.number, label: label, isSounding: hole == soundingHole)
        }
    }

    private func keyState(_ key: HarmonicaKey) -> KeyViewState {
        KeyViewState(
            label: label(for: key),
            position: Double(key.position),
            highestPosition: Double(HarmonicaKey.highestPosition)
        )
    }

    private func label(for key: HarmonicaKey) -> String {
        switch key {
        case .g: "G"
        case .aFlat: "A♭"
        case .a: "A"
        case .bFlat: "B♭"
        case .b: "B"
        case .c: "C"
        case .dFlat: "D♭"
        case .d: "D"
        case .eFlat: "E♭"
        case .e: "E"
        case .f: "F"
        case .fSharp: "F♯"
        }
    }
}
