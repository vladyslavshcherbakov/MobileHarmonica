public struct Harmonica: Equatable {
    public let key: HarmonicaKey
    public let style: PlayingStyle
    public let cup: CupDepth
    public let sounding: [Hole: SoundingReed]

    public init(key: HarmonicaKey, style: PlayingStyle, cup: CupDepth, sounding: [Hole: SoundingReed]) {
        self.key = key
        self.style = style
        self.cup = cup
        self.sounding = sounding
    }

    public var soundingHoles: Set<Hole> {
        Set(sounding.keys)
    }

    public var breath: Breath? {
        sounding.values.first?.breath
    }

    public var canBend: Bool {
        sounding.values.contains(where: \.canBend)
    }

    public var canOverbend: Bool {
        sounding.values.contains(where: \.canOverbend)
    }
}

// MARK: - SoundingReed

public struct SoundingReed: Equatable {
    public let breath: Breath
    public let unbent: MIDINote
    public let bendableSemitones: Double
    public let overbendableSemitones: Double
    public let bend: BendDepth
    public let overbend: OverbendDepth

    public init(
        breath: Breath,
        unbent: MIDINote,
        bendableSemitones: Double,
        overbendableSemitones: Double,
        bend: BendDepth,
        overbend: OverbendDepth
    ) {
        self.breath = breath
        self.unbent = unbent
        self.bendableSemitones = bendableSemitones
        self.overbendableSemitones = overbendableSemitones
        self.bend = bend
        self.overbend = overbend
    }

    public var tone: Tone {
        isOverbent
            ? Tone(pitch: pitch.pitch, bendableSemitones: 0)
            : Tone(pitch: unbent.pitch, bendableSemitones: bendableSemitones)
    }

    public var pitch: MIDINote {
        unbent.transposed(by: Int(shiftedSemitones.rounded()))
    }

    public var isShifted: Bool {
        pitch != unbent
    }

    public var isOverbent: Bool {
        pitch.number > unbent.number
    }

    public var canBend: Bool {
        bendableSemitones > 0
    }

    public var canOverbend: Bool {
        overbendableSemitones > 0
    }

    private var shiftedSemitones: Double {
        overbendableSemitones * overbend.fraction - bendableSemitones * bend.fraction
    }
}
