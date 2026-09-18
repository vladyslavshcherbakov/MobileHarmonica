struct Harmonica: Equatable {
    let key: HarmonicaKey
    let style: PlayingStyle
    let sounding: [Hole: SoundingReed]

    var soundingHoles: Set<Hole> {
        Set(sounding.keys)
    }

    var canBend: Bool {
        sounding.values.contains(where: \.canBend)
    }
}

// MARK: - SoundingReed

struct SoundingReed: Equatable {
    let unbent: MIDINote
    let bendableSemitones: Double
    let bend: BendDepth

    var pitch: MIDINote {
        unbent.transposed(by: -bentSemitones)
    }

    var isBent: Bool {
        bentSemitones != 0
    }

    var canBend: Bool {
        bendableSemitones > 0
    }

    private var bentSemitones: Int {
        Int((bendableSemitones * bend.fraction).rounded())
    }
}
