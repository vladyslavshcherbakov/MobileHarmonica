enum PlayingStyle: CaseIterable, Hashable {
    case notes
    case mouth
    case solo

    var coversTheContactWidth: Bool {
        self != .notes
    }

    var takesTheTopmostFingerOnly: Bool {
        self == .solo
    }
}
