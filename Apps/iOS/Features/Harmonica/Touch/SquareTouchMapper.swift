import CoreGraphics
import HarmonicaCore

struct SquareTouchMapper {
    private let touches: [FingerTouch]
    private let size: CGSize

    // MARK: - Public

    init(_ touches: [FingerTouch], across size: CGSize) {
        self.touches = touches
        self.size = size
    }

    var pitchShaping: PitchShaping? {
        leadingLocation.map { PitchShaping(clamping: 1 - 2 * Double($0.y / size.height)) }
    }

    var vibrato: VibratoDepth? {
        leadingLocation.map { VibratoDepth(clamping: Double($0.x / size.width)) }
    }

    var marks: [FingerMark] {
        let leading = leadingLocation

        return touches.indices.map { index in
            FingerMark(
                id: index,
                location: touches[index].location,
                diameter: FingerMark.restingDiameter,
                isTheDecidingFinger: touches[index].location == leading
            )
        }
    }

    // MARK: - Private

    private var leadingLocation: CGPoint? {
        touches.map(\.location).min { $0.y < $1.y }
    }
}
