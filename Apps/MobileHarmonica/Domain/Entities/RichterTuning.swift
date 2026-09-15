import Foundation

struct RichterTuning {
    func blowPitch(for hole: Hole) -> Measurement<UnitFrequency> {
        blowNote(for: hole).pitch
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
}
