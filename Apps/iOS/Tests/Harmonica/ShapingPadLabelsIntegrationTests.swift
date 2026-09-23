import XCTest
@testable import MobileHarmonica

@MainActor
final class ShapingPadLabelsIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_shapingPad_whenADrawReedThatBendsSounds_callsTheUpperHalfTheBend() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.25, above: -0.3)

        XCTAssertEqual(screen.playable?.shapingPad.pitchLabel, "bend ↑", "hole 3 drawn bends three semitones")
    }

    func test_shapingPad_whenABlowReedThatOverblowsSounds_callsTheUpperHalfTheOverblow() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.25, above: 0.2)

        XCTAssertEqual(screen.playable?.shapingPad.pitchLabel, "overblow ↑", "hole 3 blown overblows")
    }

    func test_shapingPad_whenADrawReedThatOverdrawsSounds_callsTheUpperHalfTheOverdraw() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.85, above: -0.3)

        XCTAssertEqual(screen.playable?.shapingPad.pitchLabel, "overdraw ↑", "hole 9 drawn overdraws")
    }

    func test_shapingPad_whenNothingSounds_namesBothTechniquesDimmed() async {
        let screen = await environment.harmonicaScreen()

        screen.liftFromTheStrip()

        XCTAssertEqual(screen.playable?.shapingPad.pitchLabel, "bend · overbend ↑")
        XCTAssertEqual(screen.playable?.shapingPad.isPitchShapingAvailable, false)
    }

    func test_shapingPad_whenTheSoundingReedNeitherBendsNorOverbends_dimsThePitchLabel() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.45, above: -0.3)

        XCTAssertEqual(screen.playable?.shapingPad.isPitchShapingAvailable, false, "hole 5 drawn does neither")
    }
}
