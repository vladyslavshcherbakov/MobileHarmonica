struct Fingerings {
    private static let overbendCost = 10

    private let tuning: RichterTuning
    private let key: HarmonicaKey

    // MARK: - Public

    init(tuning: RichterTuning, key: HarmonicaKey) {
        self.tuning = tuning
        self.key = key
    }

    func reaching(_ note: MIDINote) -> [Fingering] {
        Hole.allCases
            .flatMap { hole in [Breath.blow, .draw].compactMap { fingering(hole, $0, reaching: note) } }
            .sorted { cost(of: $0) < cost(of: $1) }
    }

    func nearest(to note: MIDINote, from previous: Hole?, breathing breath: Breath? = nil) -> Fingering? {
        let candidates = reaching(note).filter { breath == nil || $0.breath == breath }
        guard let best = candidates.first else { return nil }

        let cheapest = candidates.filter {
            $0.bentBySemitones == best.bentBySemitones && $0.isOverbent == best.isOverbent
        }
        guard let previous else { return cheapest.first }

        return cheapest.min {
            abs($0.hole.number - previous.number) < abs($1.hole.number - previous.number)
        }
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
