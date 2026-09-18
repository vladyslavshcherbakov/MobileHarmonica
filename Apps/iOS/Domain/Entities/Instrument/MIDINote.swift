import Foundation

struct MIDINote: Equatable {
    static let c4 = MIDINote(number: 60)
    static let d4 = MIDINote(number: 62)
    static let e4 = MIDINote(number: 64)
    static let g4 = MIDINote(number: 67)
    static let b4 = MIDINote(number: 71)
    static let c5 = MIDINote(number: 72)
    static let d5 = MIDINote(number: 74)
    static let e5 = MIDINote(number: 76)
    static let f5 = MIDINote(number: 77)
    static let g5 = MIDINote(number: 79)
    static let a5 = MIDINote(number: 81)
    static let b5 = MIDINote(number: 83)
    static let c6 = MIDINote(number: 84)
    static let d6 = MIDINote(number: 86)
    static let e6 = MIDINote(number: 88)
    static let f6 = MIDINote(number: 89)
    static let g6 = MIDINote(number: 91)
    static let a6 = MIDINote(number: 93)
    static let c7 = MIDINote(number: 96)

    static let namesAboveC = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    private static let concertPitch = Measurement(value: 440, unit: UnitFrequency.hertz)
    private static let concertPitchNumber = 69
    private static let semitonesPerOctave = 12

    let number: Int

    // MARK: - Public

    func transposed(by semitones: Int) -> MIDINote {
        MIDINote(number: number + semitones)
    }

    var pitch: Measurement<UnitFrequency> {
        Self.concertPitch * pow(2, semitonesFromConcertPitch / Double(Self.semitonesPerOctave))
    }

    var semitonesAboveC: Int {
        number % Self.semitonesPerOctave
    }

    var octave: Int {
        number / Self.semitonesPerOctave - 1
    }

    var name: String {
        Self.namesAboveC[semitonesAboveC] + String(octave)
    }

    // MARK: - Private

    private var semitonesFromConcertPitch: Double {
        Double(number - Self.concertPitchNumber)
    }
}
