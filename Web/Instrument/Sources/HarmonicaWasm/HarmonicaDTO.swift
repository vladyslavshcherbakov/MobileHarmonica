#if arch(wasm32)
import HarmonicaCore

struct HarmonicaDTO: Encodable {
    static let holesWideOfTheContact = 0

    let keyPosition: Int
    let style: String
    let mouthHolesWide: Int
    let cup: Double
    let canBend: Bool
    let canOverbend: Bool
    let breath: String?
    let sounding: [SoundingHoleDTO]

    init(_ harmonica: Harmonica) {
        keyPosition = harmonica.key.sliderPosition
        style = Self.name(of: harmonica.style)
        mouthHolesWide = Self.holesWide(of: harmonica.mouth)
        cup = harmonica.cup.fraction
        canBend = harmonica.canBend
        canOverbend = harmonica.canOverbend
        breath = harmonica.breath.map(Self.name(of:))
        sounding = harmonica.sounding
            .map { SoundingHoleDTO(hole: $0.key, reed: $0.value) }
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
        case .theContactItself: holesWideOfTheContact
        case .holesWide(let width): width.holes
        }
    }
}

// MARK: - SoundingHoleDTO

struct SoundingHoleDTO: Encodable {
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
#endif
