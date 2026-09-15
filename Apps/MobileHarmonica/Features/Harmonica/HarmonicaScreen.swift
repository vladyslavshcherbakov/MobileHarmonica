import SwiftUI

struct HarmonicaScreen: View {
    private static let holeSpacing: CGFloat = 6

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
            .task { viewModel.prepareSound() }
            .onChange(of: scenePhase) { _, phase in
                prepareOrSilence(for: phase)
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
            .contentShape(Rectangle())
            .gesture(blowGesture(acrossWidth: geometry.size.width))
        }
    }

    private func blowGesture(acrossWidth width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { touch in
                viewModel.blow(at: PositionAlongHarmonica(fraction: Double(touch.location.x / width)))
            }
            .onEnded { _ in
                viewModel.stopBlowing()
            }
    }

    private func prepareOrSilence(for phase: ScenePhase) {
        switch phase {
        case .active:
            viewModel.prepareSound()
        default:
            viewModel.stopBlowing()
        }
    }
}
