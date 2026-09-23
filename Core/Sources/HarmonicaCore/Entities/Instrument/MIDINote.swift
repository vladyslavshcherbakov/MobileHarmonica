import Foundation

public struct MIDINote: Equatable, Sendable {
    public static let c4 = MIDINote(number: 60)
    public static let d4 = MIDINote(number: 62)
    public static let e4 = MIDINote(number: 64)
    public static let g4 = MIDINote(number: 67)
    public static let b4 = MIDINote(number: 71)
    public static let c5 = MIDINote(number: 72)
    public static let d5 = MIDINote(number: 74)
    public static let e5 = MIDINote(number: 76)
    public static let f5 = MIDINote(number: 77)
    public static let g5 = MIDINote(number: 79)
    public static let a5 = MIDINote(number: 81)
    public static let b5 = MIDINote(number: 83)
    public static let c6 = MIDINote(number: 84)
    public static let d6 = MIDINote(number: 86)
    public static let e6 = MIDINote(number: 88)
    public static let f6 = MIDINote(number: 89)
    public static let g6 = MIDINote(number: 91)
    public static let a6 = MIDINote(number: 93)
    public static let c7 = MIDINote(number: 96)

    public static let namesAboveC = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    private static let concertPitch = Measurement(value: 440, unit: UnitFrequency.hertz)
    private static let concertPitchNumber = 69
    private static let semitonesPerOctave = 12

    public let number: Int

    // MARK: - Public

    public init(number: Int) {
        self.number = number
    }

    public func transposed(by semitones: Int) -> MIDINote {
        MIDINote(number: number + semitones)
    }

    public var pitch: Measurement<UnitFrequency> {
        Self.concertPitch * pow(2, semitonesFromConcertPitch / Double(Self.semitonesPerOctave))
    }

    public var semitonesAboveC: Int {
        number % Self.semitonesPerOctave
    }

    public var octave: Int {
        number / Self.semitonesPerOctave - 1
    }

    public var name: String {
        Self.namesAboveC[semitonesAboveC] + String(octave)
    }

    // MARK: - Private

    private var semitonesFromConcertPitch: Double {
        Double(number - Self.concertPitchNumber)
    }
}
