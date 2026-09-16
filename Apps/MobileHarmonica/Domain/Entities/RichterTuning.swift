import Foundation

struct RichterTuning {
    // MARK: - Public

    func tone(for reed: Reed, in key: HarmonicaKey) -> Tone {
        Tone(
            pitch: note(for: reed).transposed(by: key.semitonesFromC).pitch,
            bendableSemitones: bendableSemitones(for: reed)
        )
    }

    // MARK: - Private

    private func bendableSemitones(for reed: Reed) -> Double {
        let bending = note(for: reed).number
        let neighbour = note(for: Reed(hole: reed.hole, breath: reed.breath.reversed)).number
        guard bending > neighbour else { return 0 }

        return Double(bending - neighbour - 1)
    }

    private func note(for reed: Reed) -> MIDINote {
        switch reed.breath {
        case .blow: blowNote(for: reed.hole)
        case .draw: drawNote(for: reed.hole)
        }
    }

    private func blowNote(for hole: Hole) -> MIDINote {
        switch hole {
        case .one: .c4
        case .two: .e4
        case .three: .g4
        case .four: .c5
        case .five: .e5
        case .six: .g5
        case .seven: .c6
        case .eight: .e6
        case .nine: .g6
        case .ten: .c7
        }
    }

    private func drawNote(for hole: Hole) -> MIDINote {
        switch hole {
        case .one: .d4
        case .two: .g4
        case .three: .b4
        case .four: .d5
        case .five: .f5
        case .six: .a5
        case .seven: .b5
        case .eight: .d6
        case .nine: .f6
        case .ten: .a6
        }
    }
}
