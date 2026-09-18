import SwiftUI

struct FingerCircles: View {
    static let diameter: CGFloat = 56

    private static let lineWidth: CGFloat = 3

    let marks: [FingerMark]

    var body: some View {
        ForEach(marks) { mark in
            Circle()
                .strokeBorder(
                    mark.decidesBreath ? Color.white : Color(white: 0.5),
                    lineWidth: Self.lineWidth
                )
                .frame(width: mark.diameter, height: mark.diameter)
                .position(mark.location)
        }
    }
}

// MARK: - FingerMark

struct FingerMark: Identifiable {
    let id: Int
    let location: CGPoint
    let diameter: CGFloat
    let decidesBreath: Bool
}
