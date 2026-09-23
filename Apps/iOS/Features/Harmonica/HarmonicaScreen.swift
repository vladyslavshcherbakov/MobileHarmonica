import SwiftUI

@MainActor
struct HarmonicaScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HarmonicaViewModel

    private let openSettings: @MainActor () -> Void

    // MARK: - Public

    init(
        viewModel: @autoclosure @escaping @MainActor () -> HarmonicaViewModel,
        openSettings: @escaping @MainActor () -> Void
    ) {
        _viewModel = StateObject(wrappedValue: MainActor.assumeIsolated { viewModel() })
        self.openSettings = openSettings
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: edgeUnderTheSquare)
            .background(Color.black.ignoresSafeArea())
            .task(id: scenePhase) {
                await prepareOrSilence(for: scenePhase)
            }
            .task(id: isCupShown) {
                await viewModel.followTheTilt()
            }
            .onAppear { viewModel.applyTheSettings() }
    }

    // MARK: - Private

    private static func edge(under placement: SquarePlacement) -> Edge.Set {
        switch placement {
        case .left: .leading
        case .right: .trailing
        }
    }

    private var playable: HarmonicaViewState.Playable? {
        guard case .ready(let playable) = viewModel.state else { return nil }

        return playable
    }

    private var isCupShown: Bool {
        playable?.cup != nil
    }

    private var edgeUnderTheSquare: Edge.Set {
        Self.edge(under: playable?.square.placement ?? PlayerSettings.atFirstLaunch.squarePlacement)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .preparingSound:
            ProgressView()
                .tint(.white)
        case .ready(let playable):
            playableHarmonica(playable)
        case .soundUnavailable(let text):
            Text(text)
                .foregroundStyle(.white)
        }
    }

    private func playableHarmonica(_ playable: HarmonicaViewState.Playable) -> some View {
        VStack(spacing: 0) {
            KeyBar(
                playable: playable,
                clearOf: Self.edge(under: playable.square.placement),
                openSettings: openSettings,
                viewModel: viewModel
            )
            GeometryReader { geometry in
                HStack(spacing: HarmonicaStrip.holeSpacing) {
                    switch playable.square.placement {
                    case .left:
                        square(playable, within: geometry.size)
                        strip(playable)
                    case .right:
                        strip(playable)
                        square(playable, within: geometry.size)
                    }
                }
            }
        }
    }

    private func square(_ playable: HarmonicaViewState.Playable, within area: CGSize) -> some View {
        let side = SquareSizing(in: area).side(for: playable.square.size)
        return ToneShapingZone(
            state: playable.toneShaping,
            pinched: { viewModel.resizeSquare(by: $0, within: area) },
            viewModel: viewModel
        )
        .frame(width: side, height: side)
    }

    private func strip(_ playable: HarmonicaViewState.Playable) -> some View {
        HarmonicaStrip(
            holes: playable.holes,
            fingerMarks: playable.fingerMarks,
            viewModel: viewModel
        )
    }

    private func prepareOrSilence(for phase: ScenePhase) async {
        switch phase {
        case .active:
            await viewModel.prepareSound()
        default:
            viewModel.stopPlaying()
            viewModel.stopShapingTone()
        }
    }
}
