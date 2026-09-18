protocol AudioEngineProtocol: AnyObject {
    func prepare() async throws
    func soundTones(_ tones: [Tone], as change: ToneChange)
    func changeIntensity(to intensity: BreathIntensity)
    func changeBend(to depth: BendDepth)
    func changeVibrato(to depth: VibratoDepth)
    func silence()
}
