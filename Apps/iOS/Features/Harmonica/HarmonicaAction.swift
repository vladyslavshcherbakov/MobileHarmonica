import CoreGraphics

enum HarmonicaAction {
    case appBecameActive
    case appLeftTheForeground
    case screenAppeared
    case screenDisappeared
    case stripTouched([FingerTouch], across: CGSize)
    case keySliderMoved(toPosition: Double)
    case tuneChosen(at: Int)
    case stopTuneButtonTapped
    case shapingPadTouched([FingerTouch], across: CGSize)
    case shapingPadPinched(by: CGFloat, within: CGSize)
    case settingsButtonTapped
}
