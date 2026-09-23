#if arch(wasm32)
import HarmonicaCore

struct TuneDTO: Encodable {
    let name: String
    let keyPosition: Int
    let harmonicaKeyPosition: Int
    let position: String
    let beatsPerMinute: Double
    let events: [ScoreEventDTO]

    init(_ score: Score) {
        name = score.name
        keyPosition = score.key.sliderPosition
        harmonicaKeyPosition = score.harmonicaKey.sliderPosition
        position = Self.name(of: score.position)
        beatsPerMinute = score.beatsPerMinute
        events = score.events.map(ScoreEventDTO.init)
    }

    private static func name(of position: HarmonicaPosition) -> String {
        switch position {
        case .first: "first"
        case .second: "second"
        case .third: "third"
        }
    }
}

// MARK: - ScoreEventDTO

struct ScoreEventDTO: Encodable {
    let holes: [Int]
    let breath: String?
    let beats: Double
    let bentBySemitones: Double
    let isOverbent: Bool
    let vibrato: Double
    let breathIntensity: Double
    let slideFrom: Int?
    let shakenWith: Int?
    let bendEndsAtSemitones: Double?

    enum CodingKeys: String, CodingKey {
        case holes, breath, beats, bentBySemitones, isOverbent, vibrato, breathIntensity, slideFrom, shakenWith
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
            breathIntensity = 0
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
            breathIntensity = note.breathIntensity
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
        try container.encode(breathIntensity, forKey: .breathIntensity)
        try container.encode(slideFrom, forKey: .slideFrom)
        try container.encode(shakenWith, forKey: .shakenWith)
        try container.encode(bendEndsAtSemitones, forKey: .bendEndsAtSemitones)
    }
}
#endif
