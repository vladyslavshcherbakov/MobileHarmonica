import Foundation

struct HarmonicaPresenter {
    private static let soundUnavailableText = "Sound is unavailable."
    private static let overbendLabel = "overbend ↑"
    private static let bendLabel = "bend ↓"
    private static let vibratoLabel = "vibrato →"
    private static let playDemoLabel = "play"
    private static let stopDemoLabel = "stop"
    private static let bendEffectLabel = "bend"
    private static let overblowEffectLabel = "overblow"
    private static let overdrawEffectLabel = "overdraw"

    private let locale: Locale
    private let tunes: [TuneViewState]
    private let holeLabels: [String]

    // MARK: - Public

    init(locale: Locale, tunes: [Score]) {
        self.locale = locale
        self.tunes = tunes.enumerated().map { TuneViewState(id: $0.offset, name: $0.element.name) }
        holeLabels = Hole.allCases.map { $0.number.formatted(.number.locale(locale)) }
    }

    func present(_ harmonica: Harmonica, playingAScore: Bool) -> HarmonicaViewState {
        .ready(
            PlayableHarmonica(
                holes: holes(of: harmonica),
                key: keyState(harmonica.key),
                style: styleState(harmonica.style),
                fingerMarks: fingerMarksState(harmonica.style),
                demo: demoState(playingAScore),
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
            lit: sounding.map { Self.half(litBy: $0.breath) }
        )
    }

    private static func half(litBy breath: Breath) -> LitHalf {
        switch breath {
        case .blow: .top
        case .draw: .bottom
        }
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
        MIDINote.namesAboveC[note.semitonesAboveC] + note.octave.formatted(.number.locale(locale))
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
            label: Self.name(of: Self.choice(of: style)),
            choices: PlayingStyle.allCases.map(Self.choiceState(of:))
        )
    }

    private static func choiceState(of style: PlayingStyle) -> PlayingStyleChoiceViewState {
        let chosen = choice(of: style)
        return PlayingStyleChoiceViewState(id: chosen, name: name(of: chosen))
    }

    private static func choice(of style: PlayingStyle) -> PlayingStyleChoice {
        switch style {
        case .severalFingersSeveralNotes: .severalFingersSeveralNotes
        case .severalFingersOneNote: .severalFingersOneNote
        case .oneFingerSeveralNotes: .oneFingerSeveralNotes
        }
    }

    private static func name(of choice: PlayingStyleChoice) -> String {
        switch choice {
        case .severalFingersSeveralNotes: "Many fingers, many notes"
        case .severalFingersOneNote: "Many fingers, one note"
        case .oneFingerSeveralNotes: "One finger, many notes"
        }
    }

    private func fingerMarksState(_ style: PlayingStyle) -> FingerMarksViewState {
        FingerMarksViewState(
            atTheContactWidth: style.coversTheContactWidth,
            onlyTheDecidingFinger: style.takesTheTopmostFingerOnly
        )
    }

    private func demoState(_ isPlaying: Bool) -> DemoViewState {
        DemoViewState(
            label: isPlaying ? Self.stopDemoLabel : Self.playDemoLabel,
            tunes: tunes,
            isPlaying: isPlaying
        )
    }

    private func keyState(_ key: HarmonicaKey) -> KeyViewState {
        KeyViewState(
            label: label(for: key),
            position: Double(key.sliderPosition),
            highestPosition: Double(HarmonicaKey.highestSliderPosition)
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
