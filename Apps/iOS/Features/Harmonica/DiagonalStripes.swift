import SwiftUI

struct DiagonalStripes: Shape {
    let spacing: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        var start = rect.minX - rect.height
        while start < rect.maxX {
            path.move(to: CGPoint(x: start, y: rect.maxY))
            path.addLine(to: CGPoint(x: start + rect.height, y: rect.minY))
            start += spacing
        }
        return path
    }
}
