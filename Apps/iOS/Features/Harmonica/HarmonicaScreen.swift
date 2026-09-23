import SwiftUI

@MainActor
struct HarmonicaScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HarmonicaViewModel

    // MARK: - Public

    init(viewModel: @autoclosure @escaping @MainActor () -> HarmonicaViewModel) {
        _viewModel = StateObject(wrappedValue: MainActor.assumeIsolated { viewModel() })
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: edgeUnderTheShapingPad)
            .background(Color.black.ignoresSafeArea())
            .onChange(of: scenePhase, initial: true) { _, phase in viewModel.send(Self.action(for: phase)) }
            .onAppear { viewModel.send(.screenAppeared) }
            .onDisappear { viewModel.send(.screenDisappeared) }
    }

    // MARK: - Private

    private static func action(for phase: ScenePhase) -> HarmonicaAction {
        switch phase {
        case .active: .appBecameActive
        default: .appLeftTheForeground
        }
    }

    private static func edge(under placement: ShapingPadPlacement) -> Edge.Set {
        switch placement {
        case .left: .leading
        case .right: .trailing
        }
    }

    private var playable: HarmonicaViewState.Playable? {
        guard case .ready(let playable) = viewModel.state else { return nil }

        return playable
    }

    private var edgeUnderTheShapingPad: Edge.Set {
        Self.edge(under: playable?.shapingPad.placement ?? PlayerSettings.atFirstLaunch.shapingPadPlacement)
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
                clearOf: Self.edge(under: playable.shapingPad.placement),
                viewModel: viewModel
            )
            GeometryReader { geometry in
                HStack(spacing: HarmonicaStrip.holeSpacing) {
                    switch playable.shapingPad.placement {
                    case .left:
                        shapingPad(playable, within: geometry.size)
                        strip(playable)
                    case .right:
                        strip(playable)
                        shapingPad(playable, within: geometry.size)
                    }
                }
            }
        }
    }

    private func shapingPad(_ playable: HarmonicaViewState.Playable, within area: CGSize) -> some View {
        let side = ShapingPadSizing(in: area).side(for: playable.shapingPad.size)
        return ShapingPad(state: playable.shapingPad, pinchArea: area, viewModel: viewModel)
            .frame(width: side, height: side)
    }

    private func strip(_ playable: HarmonicaViewState.Playable) -> some View {
        HarmonicaStrip(
            holes: playable.holes,
            fingerMarks: playable.fingerMarks,
            viewModel: viewModel
        )
    }
}
