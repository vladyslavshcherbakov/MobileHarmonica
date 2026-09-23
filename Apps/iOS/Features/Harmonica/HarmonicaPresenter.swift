import Foundation
import HarmonicaCore

struct HarmonicaPresenter {
    private static let noRecordingsText = "Sound is unavailable: the recordings are not in the app."
    private static let outputRefusedText = "Sound is unavailable: the audio output would not start."
    private static let pitchAtRestLabel = "bend · overbend ↑"
    private static let bendLabel = "bend ↑"
    private static let overblowLabel = "overblow ↑"
    private static let overdrawLabel = "overdraw ↑"
    private static let vibratoLabel = "vibrato →"
    private static let cupLabel = "cup"
    private static let playDemoLabel = "▶\u{FE0E}"
    private static let stopDemoMark = "■\u{FE0E}"
    private static let bendEffectLabel = "bend"
    private static let overblowEffectLabel = "overblow"
    private static let overdrawEffectLabel = "overdraw"

    private let locale: Locale
    private let tunes: [HarmonicaViewState.Tune]
    private let holeLabels: [String]

    // MARK: - Public

    init(locale: Locale, tunes: [Score]) {
        self.locale = locale
        self.tunes = tunes.enumerated().map { HarmonicaViewState.Tune(id: $0.offset, name: $0.element.name) }
        holeLabels = Hole.allCases.map { $0.number.formatted(.number.locale(locale)) }
    }

    func present(_ harmonica: Harmonica, settings: PlayerSettings, playingTune: Int?) -> HarmonicaViewState {
        .ready(
            HarmonicaViewState.Playable(
                holes: holes(of: harmonica),
                key: keyState(harmonica.key),
                fingerMarks: fingerMarksState(harmonica.style),
                cup: settings.isCuppingEnabled ? Self.cupState(harmonica.cup) : nil,
                demo: demoState(playingTune: playingTune),
                shapingPad: Self.shapingPadState(harmonica, settings: settings)
            )
        )
    }

    func presentSoundUnavailable(because failure: AudioEngineError) -> HarmonicaViewState {
        .soundUnavailable(Self.reason(for: failure))
    }

    // MARK: - Private

    private static func reason(for failure: AudioEngineError) -> String {
        switch failure {
        case .noRecordings: noRecordingsText
        case .recordingUnreadable(let name): "Sound is unavailable: the recording \(name) could not be read."
        case .outputRefused: outputRefusedText
        }
    }

    private func holes(of harmonica: Harmonica) -> [HarmonicaViewState.Hole] {
        zip(Hole.allCases, holeLabels).map { hole, label in
            holeState(hole, label: label, sounding: harmonica.sounding[hole])
        }
    }

    private func holeState(_ hole: Hole, label: String, sounding: SoundingReed?) -> HarmonicaViewState.Hole {
        HarmonicaViewState.Hole(
            id: hole.number,
            label: label,
            note: sounding.map { name(of: $0.pitch) } ?? "",
            effect: sounding.map(effect(shaping:)) ?? "",
            lit: sounding.map { Self.half(litBy: $0.breath) }
        )
    }

    private static func half(litBy breath: Breath) -> HarmonicaViewState.LitHalf {
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

    private static func shapingPadState(
        _ harmonica: Harmonica,
        settings: PlayerSettings
    ) -> HarmonicaViewState.ShapingPad {
        HarmonicaViewState.ShapingPad(
            pitchLabel: pitchLabel(for: harmonica),
            vibratoLabel: vibratoLabel,
            isPitchShapingAvailable: harmonica.canBend || harmonica.canOverbend,
            placement: settings.shapingPadPlacement,
            size: settings.shapingPadSize
        )
    }

    private static func pitchLabel(for harmonica: Harmonica) -> String {
        if harmonica.canBend { return bendLabel }
        guard harmonica.canOverbend, let breath = harmonica.breath else { return pitchAtRestLabel }

        switch breath {
        case .blow: return overblowLabel
        case .draw: return overdrawLabel
        }
    }

    private static func cupState(_ cup: CupDepth) -> HarmonicaViewState.Cup {
        HarmonicaViewState.Cup(label: cupLabel, closed: cup.fraction)
    }

    private func fingerMarksState(_ style: PlayingStyle) -> HarmonicaViewState.FingerMarks {
        HarmonicaViewState.FingerMarks(
            isDrawnAtTheContactWidth: style.coversTheContactWidth,
            drawsOnlyTheDecidingFinger: style.takesTheTopmostFingerOnly
        )
    }

    private func demoState(playingTune index: Int?) -> HarmonicaViewState.Demo {
        HarmonicaViewState.Demo(
            label: demoLabel(playingTune: index),
            tunes: tunes,
            isPlaying: index != nil
        )
    }

    private func demoLabel(playingTune index: Int?) -> String {
        guard let playing = tunes.first(where: { $0.id == index }) else { return Self.playDemoLabel }

        return "\(Self.stopDemoMark) \(playing.name)"
    }

    private func keyState(_ key: HarmonicaKey) -> HarmonicaViewState.Key {
        HarmonicaViewState.Key(
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
