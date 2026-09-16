import Foundation

struct HarmonicaPresenter {
    private static let soundUnavailableText = "Sound is unavailable."
    private static let bendLabel = "bend ↓"
    private static let vibratoLabel = "vibrato →"
    private static let playingStyleLabel = "Playing style"
    private static let fingersLabel = "fingers"
    private static let mouthLabel = "mouth"

    private let holeLabels: [String]

    // MARK: - Public

    init(locale: Locale) {
        holeLabels = Hole.allCases.map { $0.number.formatted(.number.locale(locale)) }
    }

    func present(
        soundingHoles: Set<Hole>,
        key: HarmonicaKey,
        style: PlayingStyle,
        bendableSemitones: Double
    ) -> HarmonicaViewState {
        .ready(
            PlayableHarmonica(
                holes: holes(soundingHoles: soundingHoles),
                key: keyState(key),
                style: styleState(style),
                toneShaping: toneShaping(bendableSemitones: bendableSemitones)
            )
        )
    }

    func presentSoundUnavailable() -> HarmonicaViewState {
        .soundUnavailable(Self.soundUnavailableText)
    }

    // MARK: - Private

    private func holes(soundingHoles: Set<Hole>) -> [HoleViewState] {
        zip(Hole.allCases, holeLabels).map { hole, label in
            HoleViewState(id: hole.number, label: label, isSounding: soundingHoles.contains(hole))
        }
    }

    private func toneShaping(bendableSemitones: Double) -> ToneShapingViewState {
        ToneShapingViewState(
            bendLabel: Self.bendLabel,
            vibratoLabel: Self.vibratoLabel,
            bendIsAvailable: bendableSemitones > 0
        )
    }

    private func styleState(_ style: PlayingStyle) -> PlayingStyleViewState {
        PlayingStyleViewState(
            label: Self.playingStyleLabel,
            fingersLabel: Self.fingersLabel,
            mouthLabel: Self.mouthLabel,
            isMouth: style == .mouth
        )
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
