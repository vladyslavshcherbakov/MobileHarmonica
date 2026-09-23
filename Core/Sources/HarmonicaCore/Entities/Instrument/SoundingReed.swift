public struct SoundingReed: Equatable, Sendable {
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
