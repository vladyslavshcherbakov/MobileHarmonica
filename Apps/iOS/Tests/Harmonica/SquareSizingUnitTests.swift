import CoreGraphics
import XCTest
@testable import MobileHarmonica

final class SquareSizingUnitTests: XCTestCase {
    private let wideArea = SquareSizing(in: CGSize(width: 1000, height: 100))

    // MARK: - Tests

    func test_squareSize_whenAtTheBottomOfTheSlider_isTheSmallestThePinchAllows() {
        XCTAssertEqual(wideArea.side(for: SquareSize(clamping: 0)), 45, accuracy: 0.001, "0.45 of the natural 100")
    }

    func test_squareSize_whenAtTheTopOfTheSlider_fillsTheHeightOfTheArea() {
        XCTAssertEqual(wideArea.side(for: SquareSize(clamping: 1)), 100, accuracy: 0.001)
    }

    func test_squareSize_whenAtTheTopOfTheSliderInANarrowArea_isTwiceTheNaturalSide() {
        let narrowArea = SquareSizing(in: CGSize(width: 500, height: 400))

        XCTAssertEqual(narrowArea.side(for: SquareSize(clamping: 1)), 220, accuracy: 0.001, "natural is 0.22 of 500")
    }

    func test_squareSize_whenPinchedPastTheLargest_stopsAtTheTopOfTheSlider() {
        let pinched = wideArea.size(afterPinching: SquareSize(clamping: 0.5), by: 2)

        XCTAssertEqual(pinched, SquareSize(clamping: 1))
    }

    func test_squareSize_whenPinchedPastTheSmallest_stopsAtTheBottomOfTheSlider() {
        let pinched = wideArea.size(afterPinching: SquareSize(clamping: 0.5), by: 0.1)

        XCTAssertEqual(pinched, SquareSize(clamping: 0))
    }
}
