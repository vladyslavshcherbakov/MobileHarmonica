@MainActor
public protocol AudioEngineProtocol: AnyObject, Sendable {
    func prepare() async throws(AudioEngineError)
    func soundTones(_ tones: [Tone], as change: ToneChange)
    func changeIntensity(to intensity: BreathIntensity)
    func changeBend(to depth: BendDepth)
    func changeVibrato(to depth: VibratoDepth)
    func cupHands(to depth: CupDepth)
    func silence(_ release: ReedRelease)
}
