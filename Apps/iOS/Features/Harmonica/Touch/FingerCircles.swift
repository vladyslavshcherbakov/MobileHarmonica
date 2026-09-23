import SwiftUI

struct FingerCircles: View {
    private static let lineWidth: CGFloat = 3

    let marks: [FingerMark]

    var body: some View {
        ForEach(marks) { mark in
            Circle()
                .strokeBorder(
                    mark.isTheDecidingFinger ? Color.white : Color(white: 0.5),
                    lineWidth: Self.lineWidth
                )
                .frame(width: mark.diameter, height: mark.diameter)
                .position(mark.location)
        }
    }
}
