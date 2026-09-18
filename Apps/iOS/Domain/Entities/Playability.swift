struct Playability: Equatable {
    let unreachable: [MIDINote]
    let bends: Int
    let overbends: Int
    let widestLeapInHoles: Int

    var isPerfect: Bool {
        unreachable.isEmpty
    }

    var summary: String {
        let missed = unreachable.map(\.name).joined(separator: " ")
        return "\(bends) bends, \(overbends) overbends, widest leap \(widestLeapInHoles) holes"
            + (missed.isEmpty ? ", every note reachable" : ", out of reach: \(missed)")
    }
}
