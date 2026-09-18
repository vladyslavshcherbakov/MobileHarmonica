struct Harmonica: Equatable {
    let key: HarmonicaKey
    let style: PlayingStyle
    let cup: CupDepth
    let sounding: [Hole: SoundingReed]

    var soundingHoles: Set<Hole> {
        Set(sounding.keys)
    }

    var breath: Breath? {
        sounding.values.first?.breath
    }

    var canBend: Bool {
        sounding.values.contains(where: \.canBend)
    }

    var canOverbend: Bool {
        sounding.values.contains(where: \.canOverbend)
    }
}

// MARK: - SoundingReed

struct SoundingReed: Equatable {
    let breath: Breath
    let unbent: MIDINote
    let bendableSemitones: Double
    let overbendableSemitones: Double
    let bend: BendDepth
    let overbend: OverbendDepth

    var tone: Tone {
        isOverbent
            ? Tone(pitch: pitch.pitch, bendableSemitones: 0)
            : Tone(pitch: unbent.pitch, bendableSemitones: bendableSemitones)
    }

    var pitch: MIDINote {
        unbent.transposed(by: Int(shiftedSemitones.rounded()))
    }

    var isShifted: Bool {
        pitch != unbent
    }

    var isOverbent: Bool {
        pitch.number > unbent.number
    }

    var canBend: Bool {
        bendableSemitones > 0
    }

    var canOverbend: Bool {
        overbendableSemitones > 0
    }

    private var shiftedSemitones: Double {
        overbendableSemitones * overbend.fraction - bendableSemitones * bend.fraction
    }
}
