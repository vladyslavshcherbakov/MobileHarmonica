public struct Fingering: Equatable {
    public let hole: Hole
    public let breath: Breath
    public let bentBySemitones: Double
    public let isOverbent: Bool

    public init(hole: Hole, breath: Breath, bentBySemitones: Double, isOverbent: Bool) {
        self.hole = hole
        self.breath = breath
        self.bentBySemitones = bentBySemitones
        self.isOverbent = isOverbent
    }
}

// MARK: - Fingerings

public struct Fingerings {
    private static let overbendCost = 10

    private let tuning: RichterTuning
    private let key: HarmonicaKey

    // MARK: - Public

    public init(tuning: RichterTuning, key: HarmonicaKey) {
        self.tuning = tuning
        self.key = key
    }

    public func reaching(_ note: MIDINote) -> [Fingering] {
        Hole.allCases
            .flatMap { hole in [Breath.blow, .draw].compactMap { fingering(hole, $0, reaching: note) } }
            .sorted { cost(of: $0) < cost(of: $1) }
    }

    // MARK: - Private

    private func fingering(_ hole: Hole, _ breath: Breath, reaching note: MIDINote) -> Fingering? {
        let reed = Reed(hole: hole, breath: breath)
        let plain = tuning.note(for: reed, in: key).number
        let bentBy = plain - note.number
        if bentBy == 0 || (bentBy > 0 && Double(bentBy) <= tuning.bendableSemitones(for: reed)) {
            return Fingering(hole: hole, breath: breath, bentBySemitones: Double(bentBy), isOverbent: false)
        }

        let overbendable = Int(tuning.overbendableSemitones(for: reed))
        guard overbendable > 0, plain + overbendable == note.number else { return nil }

        return Fingering(hole: hole, breath: breath, bentBySemitones: 0, isOverbent: true)
    }

    private func cost(of fingering: Fingering) -> Int {
        fingering.isOverbent ? Self.overbendCost : Int(fingering.bentBySemitones)
    }
}
