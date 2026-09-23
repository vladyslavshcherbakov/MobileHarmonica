import ComposableArchitecture
import CoreGraphics
import HarmonicaCoreTestSupport
@testable import MobileHarmonica

@MainActor
final class HarmonicaScreenDriver {
    private static let stripSize = CGSize(width: 1000, height: 100)
    private static let squareSize = CGSize(width: 100, height: 100)
    private static let playingArea = CGSize(width: 1000, height: 100)

    let store: StoreOf<AppFeature>
    let viewModel: HarmonicaViewModel

    // MARK: - Public

    init(store: StoreOf<AppFeature>, viewModel: HarmonicaViewModel) {
        self.store = store
        self.viewModel = viewModel
    }

    var playable: HarmonicaViewState? {
        guard store.harmonica.sound == .ready else { return nil }

        return viewModel.state
    }

    var unavailableText: String? {
        guard case .unavailable(let text) = store.harmonica.sound else { return nil }

        return text
    }

    var isCupShown: Bool {
        store.harmonica.settings.isCuppingEnabled
    }

    var squarePlacement: SquarePlacement {
        store.harmonica.settings.squarePlacement
    }

    var squareSize: SquareSize {
        store.harmonica.settings.squareSize
    }

    func open() async {
        store.send(.harmonica(.appeared))
        store.send(.harmonica(.sceneBecameActive))
        _ = await waitUntil { self.store.harmonica.sound != .preparing }
    }

    func leave() async {
        await store.send(.harmonica(.disappeared)).finish()
    }

    func openTheSettings() async -> SettingsScreenDriver {
        store.send(.harmonica(.settingsButtonTapped))
        await leave()
        return SettingsScreenDriver(store: store)
    }

    func comeBackFromTheSettings() {
        guard let settings = store.path.ids.last else {
            preconditionFailure("the settings screen is not open")
        }

        store.send(.path(.popFrom(id: settings)))
        store.send(.harmonica(.appeared))
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

    func pinchTheSquare(by magnification: CGFloat) async {
        let size = SquareSizing(in: Self.playingArea).size(afterPinching: squareSize, by: magnification)
        await store.send(.harmonica(.squareResized(size))).finish()
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
