struct Harmonica: Equatable {
    let key: HarmonicaKey
    let style: PlayingStyle
    let overbendStyle: OverbendStyle
    let sounding: [Hole: SoundingReed]

    var soundingHoles: Set<Hole> {
        Set(sounding.keys)
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
