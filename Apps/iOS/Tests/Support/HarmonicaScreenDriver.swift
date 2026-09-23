import CoreGraphics
@testable import MobileHarmonica

@MainActor
final class HarmonicaScreenDriver {
    private static let stripSize = CGSize(width: 1000, height: 100)
    private static let squareSize = CGSize(width: 100, height: 100)
    private static let playingArea = CGSize(width: 1000, height: 100)

    let viewModel: HarmonicaViewModel

    // MARK: - Public

    init(_ viewModel: HarmonicaViewModel) {
        self.viewModel = viewModel
    }

    var playable: HarmonicaViewState.Playable? {
        guard case .ready(let playable) = viewModel.state else { return nil }

        return playable
    }

    var unavailableText: String? {
        guard case .soundUnavailable(let text) = viewModel.state else { return nil }

        return text
    }

    func hole(_ number: Int) -> HarmonicaViewState.Hole? {
        playable?.holes.first { $0.id == number }
    }

    func touchStrip(at fractionFromLeftEdge: Double, above fractionAboveCentreLine: Double) {
        touchStrip(
            with: [StripFinger(fractionFromLeftEdge: fractionFromLeftEdge, fractionAboveCentreLine: fractionAboveCentreLine)]
        )
    }

    func touchStrip(with fingers: [StripFinger]) {
        viewModel.play(fingers.map(Self.touch(of:)), across: Self.stripSize)
    }

    func liftFromTheStrip() {
        viewModel.play([], across: Self.stripSize)
    }

    func touchSquare(pitch: Double, vibrato: Double) {
        let location = CGPoint(
            x: vibrato * Self.squareSize.width,
            y: (1 - pitch) / 2 * Self.squareSize.height
        )
        viewModel.shapeTone(with: [FingerTouch(location: location, radius: 0)], across: Self.squareSize)
    }

    func liftFromTheSquare() {
        viewModel.shapeTone(with: [], across: Self.squareSize)
    }

    func pinchTheSquare(by magnification: CGFloat) {
        viewModel.resizeSquare(by: magnification, within: Self.playingArea)
    }

    func comeBackFromTheSettings() {
        viewModel.applyTheSettings()
    }

    func moveTheKeySlider(to position: Double) {
        viewModel.changeKey(toPosition: position)
    }

    func playTune(at index: Int) {
        viewModel.playTheTune(at: index)
    }

    func stopTheTune() {
        viewModel.stopTheTune()
    }

    func followThePhone() async {
        await viewModel.followTheTilt()
    }

    // MARK: - Private

    private static func touch(of finger: StripFinger) -> FingerTouch {
        FingerTouch(
            location: CGPoint(
                x: finger.fractionFromLeftEdge * stripSize.width,
                y: (0.5 - finger.fractionAboveCentreLine) * stripSize.height
            ),
            radius: finger.fractionCoveredEitherSide * stripSize.width
        )
    }
}
