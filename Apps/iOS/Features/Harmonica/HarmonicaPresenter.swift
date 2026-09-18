import Foundation

struct HarmonicaPresenter {
    private static let soundUnavailableText = "Sound is unavailable."
    private static let overbendLabel = "overbend ↑"
    private static let bendLabel = "bend ↓"
    private static let vibratoLabel = "vibrato →"
    private static let fingersLabel = "fingers"
    private static let mouthLabel = "mouth"
    private static let smoothLabel = "smooth"
    private static let snapLabel = "snap"
    private static let bendEffectLabel = "bend"
    private static let overblowEffectLabel = "overblow"
    private static let overdrawEffectLabel = "overdraw"
    private static let noteNames = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    private let locale: Locale
    private let holeLabels: [String]

    // MARK: - Public

    init(locale: Locale) {
        self.locale = locale
        holeLabels = Hole.allCases.map { $0.number.formatted(.number.locale(locale)) }
    }

    func present(_ harmonica: Harmonica) -> HarmonicaViewState {
        .ready(
            PlayableHarmonica(
                holes: holes(of: harmonica),
                key: keyState(harmonica.key),
                style: styleState(harmonica.style),
                overbendStyle: overbendStyleState(harmonica.overbendStyle),
                toneShaping: toneShaping(harmonica)
            )
        )
    }

    func presentSoundUnavailable() -> HarmonicaViewState {
        .soundUnavailable(Self.soundUnavailableText)
    }

    // MARK: - Private

    private func holes(of harmonica: Harmonica) -> [HoleViewState] {
        zip(Hole.allCases, holeLabels).map { hole, label in
            holeState(hole, label: label, sounding: harmonica.sounding[hole])
        }
    }

    private func holeState(_ hole: Hole, label: String, sounding: SoundingReed?) -> HoleViewState {
        HoleViewState(
            id: hole.number,
            label: label,
            note: sounding.map { name(of: $0.pitch) } ?? "",
            effect: sounding.map(effect(shaping:)) ?? "",
            isSounding: sounding != nil
        )
    }

    private func effect(shaping reed: SoundingReed) -> String {
        guard reed.isShifted else { return "" }

        return "(\(name(of: reed.unbent)) \(effectName(shaping: reed)))"
    }

    private func effectName(shaping reed: SoundingReed) -> String {
        guard reed.isOverbent else { return Self.bendEffectLabel }

        return reed.breath == .blow ? Self.overblowEffectLabel : Self.overdrawEffectLabel
    }

    private func name(of note: MIDINote) -> String {
        Self.noteNames[note.semitonesAboveC] + note.octave.formatted(.number.locale(locale))
    }

    private func toneShaping(_ harmonica: Harmonica) -> ToneShapingViewState {
        ToneShapingViewState(
            overbendLabel: Self.overbendLabel,
            bendLabel: Self.bendLabel,
            vibratoLabel: Self.vibratoLabel,
            overbendIsAvailable: harmonica.canOverbend,
            bendIsAvailable: harmonica.canBend
        )
    }

    private func styleState(_ style: PlayingStyle) -> PlayingStyleViewState {
        PlayingStyleViewState(
            fingersLabel: Self.fingersLabel,
            mouthLabel: Self.mouthLabel,
            isMouth: style == .mouth
        )
    }

    private func overbendStyleState(_ style: OverbendStyle) -> OverbendStyleViewState {
        OverbendStyleViewState(
            smoothLabel: Self.smoothLabel,
            snapLabel: Self.snapLabel,
            isSnap: style == .snap
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
