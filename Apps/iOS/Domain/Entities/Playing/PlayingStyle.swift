enum PlayingStyle: CaseIterable, Hashable {
    case severalFingersSeveralNotes
    case severalFingersOneNote
    case oneFingerSeveralNotes

    var coversTheContactWidth: Bool {
        self != .severalFingersOneNote
    }

    var takesTheTopmostFingerOnly: Bool {
        self == .oneFingerSeveralNotes
    }
}
