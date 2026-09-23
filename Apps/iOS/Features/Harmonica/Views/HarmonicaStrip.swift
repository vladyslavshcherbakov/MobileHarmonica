import SwiftUI

@MainActor
struct HarmonicaStrip: View {
    static let holeSpacing: CGFloat = 6

    private static let noteRowHeight: CGFloat = 30

    let holes: [HarmonicaViewState.Hole]
    let fingerMarks: HarmonicaViewState.FingerMarks
    @ObservedObject var viewModel: HarmonicaViewModel
    @State private var touches: [FingerTouch] = []

    // MARK: - Public

    var body: some View {
        VStack(spacing: 0) {
            noteRow
            GeometryReader { geometry in
                plates
                    .overlay {
                        FingerCircles(
                            marks: viewModel.marksOnTheStrip(for: touches, across: geometry.size, style: fingerMarks)
                        )
                    }
                    .overlay { touchArea(across: geometry.size) }
            }
        }
    }

    // MARK: - Private

    private var noteRow: some View {
        HStack(spacing: Self.holeSpacing) {
            ForEach(holes) { hole in
                soundingNote(hole)
            }
        }
        .frame(height: Self.noteRowHeight)
    }

    private func soundingNote(_ hole: HarmonicaViewState.Hole) -> some View {
        VStack(spacing: 0) {
            Text(hole.note)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white)
            Text(hole.effect)
                .font(.caption2)
                .foregroundStyle(Color(white: 0.5))
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity)
    }

    private var plates: some View {
        HStack(spacing: Self.holeSpacing) {
            ForEach(holes) { hole in
                HoleView(state: hole)
            }
        }
    }

    private func touchArea(across size: CGSize) -> some View {
        TouchArea { touches in
            self.touches = touches
            viewModel.play(touches, across: size)
        }
    }
}
