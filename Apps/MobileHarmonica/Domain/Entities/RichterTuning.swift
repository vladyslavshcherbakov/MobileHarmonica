import Foundation

struct RichterTuning {
    func pitch(for reed: Reed) -> Measurement<UnitFrequency> {
        note(for: reed).pitch
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
