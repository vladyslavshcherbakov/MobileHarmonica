import CoreGraphics
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

@MainActor
final class HarmonicaScreenDriver {
    private static let stripSize = CGSize(width: 1000, height: 100)
    private static let shapingPadSize = CGSize(width: 100, height: 100)
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

    func open() async {
        viewModel.send(.screenAppeared)
        viewModel.send(.appBecameActive)
        _ = await waitUntil {
            guard case .preparingSound = self.viewModel.state else { return true }

            return false
        }
    }

    func leave() {
        viewModel.send(.screenDisappeared)
    }

    func comeBack() {
        viewModel.send(.screenAppeared)
    }

    func sendTheAppToTheBackground() {
        viewModel.send(.appLeftTheForeground)
    }

    func touchStrip(at fractionFromLeftEdge: Double, above fractionAboveCentreLine: Double) {
        touchStrip(
            with: [StripFinger(fractionFromLeftEdge: fractionFromLeftEdge, fractionAboveCentreLine: fractionAboveCentreLine)]
        )
    }

    func touchStrip(with fingers: [StripFinger]) {
        viewModel.send(.stripTouched(fingers.map(Self.touch(of:)), across: Self.stripSize))
    }

    func liftFromTheStrip() {
        viewModel.send(.stripTouched([], across: Self.stripSize))
    }

    func touchShapingPad(heightAboveTheMiddle: Double, vibrato: Double) {
        let location = CGPoint(
            x: vibrato * Self.shapingPadSize.width,
            y: (1 - heightAboveTheMiddle) / 2 * Self.shapingPadSize.height
        )
        viewModel.send(.shapingPadTouched([FingerTouch(location: location, radius: 0)], across: Self.shapingPadSize))
    }

    func liftFromTheShapingPad() {
        viewModel.send(.shapingPadTouched([], across: Self.shapingPadSize))
    }

    func pinchTheShapingPad(by magnification: CGFloat) {
        viewModel.send(.shapingPadPinched(by: magnification, within: Self.playingArea))
    }

    func moveTheKeySlider(to position: Double) {
        viewModel.send(.keySliderMoved(toPosition: position))
    }

    func playTune(at index: Int) {
        viewModel.send(.tuneChosen(at: index))
    }

    func stopTheTune() {
        viewModel.send(.stopTuneButtonTapped)
    }

    func tapTheSettingsButton() {
        viewModel.send(.settingsButtonTapped)
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
