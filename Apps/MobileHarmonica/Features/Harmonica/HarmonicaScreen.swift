import SwiftUI

struct HarmonicaScreen: View {
    private static let holeSpacing: CGFloat = 6
    private static let centreLineThickness: CGFloat = 1

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HarmonicaViewModel

    // MARK: - Public

    init(viewModel: @autoclosure @escaping () -> HarmonicaViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.ignoresSafeArea())
            .task(id: scenePhase) {
                await prepareOrSilence(for: scenePhase)
            }
    }

    // MARK: - Private

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .preparingSound:
            ProgressView()
                .tint(.white)
        case .ready(let holes):
            harmonica(holes)
        case .soundUnavailable(let text):
            Text(text)
                .foregroundStyle(.white)
                .accessibilityIdentifier("harmonica.soundUnavailable")
        }
    }

    private func harmonica(_ holes: [HoleViewState]) -> some View {
        GeometryReader { geometry in
            HStack(spacing: Self.holeSpacing) {
                ForEach(holes) { hole in
                    HoleView(state: hole)
                }
            }
            .overlay { centreLine }
            .contentShape(Rectangle())
            .gesture(playGesture(across: geometry.size))
        }
    }

    private var centreLine: some View {
        Rectangle()
            .fill(Color(white: 0.45))
            .frame(height: Self.centreLineThickness)
            .accessibilityHidden(true)
    }

    private func playGesture(across size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { touch in
                viewModel.play(at: position(of: touch.location, across: size))
            }
            .onEnded { _ in
                viewModel.stopPlaying()
            }
    }

    private func position(of location: CGPoint, across size: CGSize) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: Double(location.x / size.width),
            fractionAboveCentreLine: Double((size.height / 2 - location.y) / size.height)
        )
    }

    private func prepareOrSilence(for phase: ScenePhase) async {
        switch phase {
        case .active:
            await viewModel.prepareSound()
        default:
            viewModel.stopPlaying()
        }
    }
}
