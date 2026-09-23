import CoreGraphics
import XCTest
@testable import MobileHarmonica

final class ShapingPadSizingUnitTests: XCTestCase {
    private let wideArea = ShapingPadSizing(in: CGSize(width: 1000, height: 100))

    // MARK: - Tests

    func test_shapingPadSize_whenAtTheBottomOfTheSlider_isTheSmallestThePinchAllows() {
        XCTAssertEqual(wideArea.side(for: ShapingPadSize(clamping: 0)), 45, accuracy: 0.001, "0.45 of the natural 100")
    }

    func test_shapingPadSize_whenAtTheTopOfTheSlider_fillsTheHeightOfTheArea() {
        XCTAssertEqual(wideArea.side(for: ShapingPadSize(clamping: 1)), 100, accuracy: 0.001)
    }

    func test_shapingPadSize_whenAtTheTopOfTheSliderInANarrowArea_isTwiceTheNaturalSide() {
        let narrowArea = ShapingPadSizing(in: CGSize(width: 500, height: 400))

        XCTAssertEqual(narrowArea.side(for: ShapingPadSize(clamping: 1)), 220, accuracy: 0.001, "natural is 0.22 of 500")
    }

    func test_shapingPadSize_whenPinchedPastTheLargest_stopsAtTheTopOfTheSlider() {
        let pinched = wideArea.size(afterPinching: ShapingPadSize(clamping: 0.5), by: 2)

        XCTAssertEqual(pinched, ShapingPadSize(clamping: 1))
    }

    func test_shapingPadSize_whenPinchedPastTheSmallest_stopsAtTheBottomOfTheSlider() {
        let pinched = wideArea.size(afterPinching: ShapingPadSize(clamping: 0.5), by: 0.1)

        XCTAssertEqual(pinched, ShapingPadSize(clamping: 0))
    }
}
