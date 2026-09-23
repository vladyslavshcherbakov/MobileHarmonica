import HarmonicaCore

struct PlayerSettings: Equatable {
    static let atFirstLaunch = PlayerSettings(
        style: .severalFingersSeveralNotes,
        isCuppingEnabled: true,
        shapingPadPlacement: .left,
        shapingPadSize: .atFirstLaunch
    )

    var style: PlayingStyle
    var isCuppingEnabled: Bool
    var shapingPadPlacement: ShapingPadPlacement
    var shapingPadSize: ShapingPadSize
}
