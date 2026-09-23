import XCTest
@testable import MobileHarmonica

@MainActor
final class NoteRowIntegrationTests: XCTestCase {
    private let environment = TestEnvironment()

    // MARK: - Tests

    func test_noteRow_whenNoHoleSounds_namesNothing() async {
        let screen = await environment.harmonicaScreen()

        screen.liftFromTheStrip()

        XCTAssertEqual(screen.hole(4)?.note, "")
        XCTAssertEqual(screen.hole(4)?.effect, "")
    }

    func test_noteRow_whenTheFingerIsAboveTheLine_namesTheBlowReed() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.35, above: 0.2)

        XCTAssertEqual(screen.hole(4)?.note, "C5")
    }

    func test_noteRow_whenTheFingerIsBelowTheLine_namesTheDrawReed() async {
        let screen = await environment.harmonicaScreen()

        screen.touchStrip(at: 0.35, above: -0.3)

        XCTAssertEqual(screen.hole(4)?.note, "D5")
    }

    func test_noteRow_whenTheDrawReedIsBentToItsLimit_namesTheBentNoteAndTheReedBehindIt() async {
        let screen = await environment.harmonicaScreen()
        screen.touchStrip(at: 0.35, above: -0.3)

        screen.touchSquare(pitch: -1, vibrato: 0)

        XCTAssertEqual(screen.hole(4)?.note, "D♭5")
        XCTAssertEqual(screen.hole(4)?.effect, "(D5 bend)")
    }

    func test_noteRow_whenTheBlowReedIsOverbent_namesTheOverblow() async {
        let screen = await environment.harmonicaScreen()
        screen.touchStrip(at: 0.25, above: 0.2)

        screen.touchSquare(pitch: 1, vibrato: 0)

        XCTAssertEqual(screen.hole(3)?.note, "C5")
        XCTAssertEqual(screen.hole(3)?.effect, "(G4 overblow)")
    }

    func test_noteRow_whenTheDrawReedIsOverbent_namesTheOverdraw() async {
        let screen = await environment.harmonicaScreen()
        screen.touchStrip(at: 0.85, above: -0.3)

        screen.touchSquare(pitch: 1, vibrato: 0)

        XCTAssertEqual(screen.hole(9)?.note, "A♭6")
        XCTAssertEqual(screen.hole(9)?.effect, "(F6 overdraw)")
    }

    func test_noteRow_whenTheBendRoundsToNoSemitone_namesOnlyTheNote() async {
        let screen = await environment.harmonicaScreen()
        screen.touchStrip(at: 0.25, above: -0.3)

        screen.touchSquare(pitch: -0.1, vibrato: 0)

        XCTAssertEqual(screen.hole(3)?.note, "B4")
        XCTAssertEqual(screen.hole(3)?.effect, "")
    }

    func test_noteRow_whenTheKeyIsD_namesTheReedInThatKey() async {
        let screen = await environment.harmonicaScreen()
        screen.touchStrip(at: 0.05, above: 0.2)

        screen.moveTheKeySlider(to: 7)

        XCTAssertEqual(screen.hole(1)?.note, "D4", "the slider runs from G at 0, so D is at 7")
    }
}
