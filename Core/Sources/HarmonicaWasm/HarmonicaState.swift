#if arch(wasm32)
import HarmonicaCore

struct HarmonicaState: Encodable {
    let keyPosition: Int
    let style: String
    let mouthHolesWide: Int
    let cup: Double
    let canBend: Bool
    let canOverbend: Bool
    let breath: String?
    let sounding: [SoundingHoleState]

    init(_ harmonica: Harmonica) {
        keyPosition = harmonica.key.sliderPosition
        style = Self.name(of: harmonica.style)
        mouthHolesWide = Self.holesWide(of: harmonica.mouth)
        cup = harmonica.cup.fraction
        canBend = harmonica.canBend
        canOverbend = harmonica.canOverbend
        breath = harmonica.breath.map(Self.name(of:))
        sounding = harmonica.sounding
            .map { SoundingHoleState(hole: $0.key, reed: $0.value) }
            .sorted { $0.hole < $1.hole }
    }

    enum CodingKeys: String, CodingKey {
        case keyPosition, style, mouthHolesWide, cup, canBend, canOverbend, breath, sounding
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyPosition, forKey: .keyPosition)
        try container.encode(style, forKey: .style)
        try container.encode(mouthHolesWide, forKey: .mouthHolesWide)
        try container.encode(cup, forKey: .cup)
        try container.encode(canBend, forKey: .canBend)
        try container.encode(canOverbend, forKey: .canOverbend)
        try container.encode(breath, forKey: .breath)
        try container.encode(sounding, forKey: .sounding)
    }

    private static func name(of style: PlayingStyle) -> String {
        switch style {
        case .severalFingersSeveralNotes: "severalFingersSeveralNotes"
        case .severalFingersOneNote: "severalFingersOneNote"
        case .oneFingerSeveralNotes: "oneFingerSeveralNotes"
        }
    }

    private static func name(of breath: Breath) -> String {
        switch breath {
        case .blow: "blow"
        case .draw: "draw"
        }
    }

    private static func holesWide(of mouth: MouthMeasure) -> Int {
        switch mouth {
        case .theContactItself: 0
        case .holesWide(let width): width.holes
        }
    }
}

// MARK: - SoundingHoleState

struct SoundingHoleState: Encodable {
    let hole: Int
    let breath: String
    let pitch: Int
    let unbent: Int
    let isShifted: Bool
    let isOverbent: Bool

    init(hole: Hole, reed: SoundingReed) {
        self.hole = hole.number
        breath = reed.breath == .blow ? "blow" : "draw"
        pitch = reed.pitch.number
        unbent = reed.unbent.number
        isShifted = reed.isShifted
        isOverbent = reed.isOverbent
    }
}

// MARK: - ReedState

struct ReedState: Encodable {
    let hole: Int
    let breath: String
    let bendableSemitones: Double
    let overbendableSemitones: Double

    init(hole: Hole, breath: Breath, tuning: RichterTuning) {
        self.hole = hole.number
        self.breath = breath == .blow ? "blow" : "draw"
        bendableSemitones = tuning.bendableSemitones(for: Reed(hole: hole, breath: breath))
        overbendableSemitones = tuning.overbendableSemitones(for: Reed(hole: hole, breath: breath))
    }
}

// MARK: - TuneState

struct TuneState: Encodable {
    let name: String
    let keyPosition: Int
    let harmonicaKeyPosition: Int
    let position: String
    let beatsPerMinute: Double
    let events: [EventState]

    init(_ score: Score) {
        name = score.name
        keyPosition = score.key.sliderPosition
        harmonicaKeyPosition = score.harmonicaKey.sliderPosition
        position = Self.name(of: score.position)
        beatsPerMinute = score.beatsPerMinute
        events = score.events.map(EventState.init)
    }

    private static func name(of position: HarmonicaPosition) -> String {
        switch position {
        case .first: "first"
        case .second: "second"
        case .third: "third"
        }
    }
}

// MARK: - EventState

struct EventState: Encodable {
    let holes: [Int]
    let breath: String?
    let beats: Double
    let bentBySemitones: Double
    let isOverbent: Bool
    let vibrato: Double
    let slideFrom: Int?
    let shakenWith: Int?
    let bendEndsAtSemitones: Double?

    enum CodingKeys: String, CodingKey {
        case holes, breath, beats, bentBySemitones, isOverbent, vibrato, slideFrom, shakenWith
        case bendEndsAtSemitones
    }

    init(_ event: ScoreEvent) {
        switch event {
        case .rest(let beats):
            holes = []
            breath = nil
            self.beats = beats
            bentBySemitones = 0
            isOverbent = false
            vibrato = 0
            slideFrom = nil
            shakenWith = nil
            bendEndsAtSemitones = nil
        case .note(let note):
            holes = note.holes.map(\.number)
            breath = note.breath == .blow ? "blow" : "draw"
            beats = note.beats
            bentBySemitones = note.bentBySemitones
            isOverbent = note.isOverbent
            vibrato = note.vibrato
            slideFrom = note.slideFrom?.number
            shakenWith = note.shakenWith?.number
            bendEndsAtSemitones = note.bendEndsAtSemitones
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(holes, forKey: .holes)
        try container.encode(breath, forKey: .breath)
        try container.encode(beats, forKey: .beats)
        try container.encode(bentBySemitones, forKey: .bentBySemitones)
        try container.encode(isOverbent, forKey: .isOverbent)
        try container.encode(vibrato, forKey: .vibrato)
        try container.encode(slideFrom, forKey: .slideFrom)
        try container.encode(shakenWith, forKey: .shakenWith)
        try container.encode(bendEndsAtSemitones, forKey: .bendEndsAtSemitones)
    }
}
#endif
