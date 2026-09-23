public enum PlayingStyle: CaseIterable, Hashable, Sendable {
    case severalFingersSeveralNotes
    case severalFingersOneNote
    case oneFingerSeveralNotes

    public var coversTheContactWidth: Bool {
        self != .severalFingersOneNote
    }

    public var takesTheTopmostFingerOnly: Bool {
        self == .oneFingerSeveralNotes
    }
}
