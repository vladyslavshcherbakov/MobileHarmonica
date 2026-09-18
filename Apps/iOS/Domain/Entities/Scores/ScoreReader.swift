import Foundation

struct ScoreReader {
    private static let restMark = "-"
    private static let chordSeparator = "+"
    private static let commentMark = "#"
    private static let semitonesAboveC = ["C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11]

    private let tuning: RichterTuning

    // MARK: - Public

    init(tuning: RichterTuning) {
        self.tuning = tuning
    }

    func read(_ text: String, named name: String) throws -> ReadScore {
        var header = ScoreHeader()
        var written: [WrittenEvent] = []
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            try read(String(line), into: &header, and: &written)
        }
        return try scored(header, written, named: name)
    }

    // MARK: - Private

    private func read(_ line: String, into header: inout ScoreHeader, and written: inout [WrittenEvent]) throws {
        let words = line.prefix { String($0) != Self.commentMark }.split(separator: " ").map(String.init)
        guard let first = words.first else { return }

        switch first {
        case "key": header.key = try Self.key(named: try Self.second(of: words))
        case "position": header.position = try Self.position(named: try Self.second(of: words))
        case "tempo": header.beatsPerMinute = try Self.number(try Self.second(of: words))
        default: written.append(try Self.written(words))
        }
    }

    private func scored(_ header: ScoreHeader, _ written: [WrittenEvent], named name: String) throws -> ReadScore {
        guard let key = header.key else { throw ScoreTextError.missingHeader("key") }
        guard let position = header.position else { throw ScoreTextError.missingHeader("position") }
        guard let beatsPerMinute = header.beatsPerMinute else { throw ScoreTextError.missingHeader("tempo") }

        let harmonicaKey = HarmonicaKey(
            transposedBy: key.semitonesFromC - position.semitonesAboveTheHarmonica
        )
        let played = play(written, on: Fingerings(tuning: tuning, key: harmonicaKey))
        return ReadScore(
            score: Score(
                name: name,
                key: key,
                position: position,
                beatsPerMinute: beatsPerMinute,
                events: played.events
            ),
            playability: played.playability
        )
    }

    private func play(
        _ written: [WrittenEvent],
        on fingerings: Fingerings
    ) -> (events: [ScoreEvent], playability: Playability) {
        var events: [ScoreEvent] = []
        var unreachable: [MIDINote] = []
        var bends = 0
        var overbends = 0
        var leap = 0
        var previous: Hole?

        for entry in written {
            guard !entry.pitches.isEmpty else {
                events.append(.rest(beats: entry.beats))
                continue
            }

            guard let leading = fingerings.nearest(to: entry.pitches[0], from: previous) else {
                unreachable += entry.pitches
                continue
            }

            let rest = entry.pitches.dropFirst().map {
                (pitch: $0, fingering: fingerings.nearest(to: $0, from: previous, breathing: leading.breath))
            }
            unreachable += rest.filter { $0.fingering == nil }.map(\.pitch)
            let playable = [leading] + rest.compactMap(\.fingering)
            bends += playable.filter { $0.bentBySemitones > 0 }.count
            overbends += playable.filter(\.isOverbent).count
            leap = max(leap, previous.map { abs(leading.hole.number - $0.number) } ?? 0)
            previous = leading.hole
            events.append(Self.event(of: playable, lasting: entry.beats))
        }

        return (
            events,
            Playability(
                unreachable: unreachable,
                bends: bends,
                overbends: overbends,
                widestLeapInHoles: leap
            )
        )
    }

    private static func event(of playable: [Fingering], lasting beats: Double) -> ScoreEvent {
        let leading = playable[0]
        return .note(
            ScoreNote(
                holes: playable.map(\.hole),
                breath: leading.breath,
                beats: beats,
                bentBySemitones: leading.bentBySemitones,
                isOverbent: leading.isOverbent
            )
        )
    }

    private static func written(_ words: [String]) throws -> WrittenEvent {
        guard words.count == 2 else { throw ScoreTextError.badLine(words.joined(separator: " ")) }

        let beats = try number(words[1])
        guard words[0] != restMark else { return WrittenEvent(pitches: [], beats: beats) }

        return WrittenEvent(
            pitches: try words[0].components(separatedBy: chordSeparator).map(pitch(named:)),
            beats: beats
        )
    }

    private static func pitch(named name: String) throws -> MIDINote {
        guard let octave = name.last.flatMap({ Int(String($0)) }) else { throw ScoreTextError.badPitch(name) }

        return MIDINote(number: try semitones(spelled: String(name.dropLast())) + 12 * (octave + 1))
    }

    private static func key(named name: String) throws -> HarmonicaKey {
        HarmonicaKey(transposedBy: try semitones(spelled: name))
    }

    private static func semitones(spelled name: String) throws -> Int {
        var letters = name
        var accidental = 0
        if letters.hasSuffix("#") { accidental = 1 } else if letters.hasSuffix("b") { accidental = -1 }
        if accidental != 0 { letters = String(letters.dropLast()) }
        guard let semitones = semitonesAboveC[letters.uppercased()] else { throw ScoreTextError.badPitch(name) }

        return semitones + accidental
    }

    private static func position(named name: String) throws -> HarmonicaPosition {
        switch name {
        case "first": .first
        case "second": .second
        case "third": .third
        default: throw ScoreTextError.unknownPosition(name)
        }
    }

    private static func number(_ word: String) throws -> Double {
        guard let value = Double(word), value > 0 else { throw ScoreTextError.badLength(word) }

        return value
    }

    private static func second(of words: [String]) throws -> String {
        guard words.count >= 2 else { throw ScoreTextError.badLine(words.joined(separator: " ")) }

        return words[1]
    }
}

// MARK: - ReadScore

struct ReadScore: Equatable {
    let score: Score
    let playability: Playability
}

// MARK: - ScoreHeader

private struct ScoreHeader {
    var key: HarmonicaKey?
    var position: HarmonicaPosition?
    var beatsPerMinute: Double?
}

// MARK: - WrittenEvent

private struct WrittenEvent {
    let pitches: [MIDINote]
    let beats: Double
}

// MARK: - ScoreTextError

enum ScoreTextError: Error {
    case missingHeader(String)
    case unknownPosition(String)
    case badLine(String)
    case badPitch(String)
    case badLength(String)
}

// MARK: - Fingerings + nearest

private extension Fingerings {
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
}
