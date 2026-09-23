import HarmonicaCore

struct PlayerSettings: Equatable {
    static let atFirstLaunch = PlayerSettings(
        style: .severalFingersSeveralNotes,
        isCuppingEnabled: true,
        squarePlacement: .left,
        squareSize: .atFirstLaunch
    )

    var style: PlayingStyle
    var isCuppingEnabled: Bool
    var squarePlacement: SquarePlacement
    var squareSize: SquareSize
}
