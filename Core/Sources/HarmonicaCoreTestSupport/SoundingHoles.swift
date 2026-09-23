import HarmonicaCore

public extension Harmonica {
    var soundingHoles: Set<Hole> {
        Set(sounding.keys)
    }
}
