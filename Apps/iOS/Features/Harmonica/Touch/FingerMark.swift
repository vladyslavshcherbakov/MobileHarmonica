import CoreGraphics

struct FingerMark: Identifiable {
    static let restingDiameter: CGFloat = 56

    let id: Int
    let location: CGPoint
    let diameter: CGFloat
    let isTheDecidingFinger: Bool
}
