import Foundation

struct MIDINote: Equatable {
    static let c4 = MIDINote(number: 60)
    static let e4 = MIDINote(number: 64)
    static let g4 = MIDINote(number: 67)
    static let c5 = MIDINote(number: 72)
    static let e5 = MIDINote(number: 76)
    static let g5 = MIDINote(number: 79)
    static let c6 = MIDINote(number: 84)
    static let e6 = MIDINote(number: 88)
    static let g6 = MIDINote(number: 91)
    static let c7 = MIDINote(number: 96)

    private static let concertPitch = Measurement(value: 440, unit: UnitFrequency.hertz)
    private static let concertPitchNumber = 69
    private static let semitonesPerOctave = 12.0

    let number: Int

    var pitch: Measurement<UnitFrequency> {
        Self.concertPitch * pow(2, semitonesFromConcertPitch / Self.semitonesPerOctave)
    }

    private var semitonesFromConcertPitch: Double {
        Double(number - Self.concertPitchNumber)
    }
}
