import ComposableArchitecture
import SwiftUI

@MainActor
struct HarmonicaScreen: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel: HarmonicaViewModel
    @State private var pinchedSize: SquareSize?

    private let store: StoreOf<HarmonicaFeature>

    // MARK: - Public

    init(store: StoreOf<HarmonicaFeature>, viewModel: HarmonicaViewModel) {
        self.store = store
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: edgeUnderTheSquare)
            .background(Color.black.ignoresSafeArea())
            .onChange(of: scenePhase, initial: true) { _, phase in
                store.send(phase == .active ? .sceneBecameActive : .sceneLeftTheForeground)
            }
            .onAppear { store.send(.appeared) }
            .onDisappear { store.send(.disappeared) }
    }

    // MARK: - Private

    private static func edge(under placement: SquarePlacement) -> Edge.Set {
        switch placement {
        case .left: .leading
        case .right: .trailing
        }
    }

    private var edgeUnderTheSquare: Edge.Set {
        Self.edge(under: store.settings.squarePlacement)
    }

    private var shownSquareSize: SquareSize {
        pinchedSize ?? store.settings.squareSize
    }

    @ViewBuilder
    private var content: some View {
        switch store.sound {
        case .preparing:
            waiting
        case .ready:
            if let state = viewModel.state {
                playableHarmonica(state)
            } else {
                waiting
            }
        case .unavailable(let text):
            Text(text)
                .foregroundStyle(.white)
        }
    }

    private var waiting: some View {
        ProgressView()
            .tint(.white)
    }

    private func playableHarmonica(_ state: HarmonicaViewState) -> some View {
        VStack(spacing: 0) {
            KeyBar(
                state: state,
                isCupShown: store.settings.isCuppingEnabled,
                clearOf: edgeUnderTheSquare,
                openSettings: { store.send(.settingsButtonTapped) },
                viewModel: viewModel
            )
            GeometryReader { geometry in
                HStack(spacing: HarmonicaStrip.holeSpacing) {
                    switch store.settings.squarePlacement {
                    case .left:
                        square(state, within: geometry.size)
                        strip(state)
                    case .right:
                        strip(state)
                        square(state, within: geometry.size)
                    }
                }
            }
        }
    }

    private func square(_ state: HarmonicaViewState, within area: CGSize) -> some View {
        let sizing = SquareSizing(in: area)
        let side = sizing.side(for: shownSquareSize)
        return ToneShapingZone(
            state: state.toneShaping,
            pinched: { pinch(by: $0, sizing: sizing) },
            pinchEnded: finishPinching,
            viewModel: viewModel
        )
        .frame(width: side, height: side)
    }

    private func strip(_ state: HarmonicaViewState) -> some View {
        HarmonicaStrip(
            holes: state.holes,
            fingerMarks: state.fingerMarks,
            viewModel: viewModel
        )
    }

    private func pinch(by magnification: CGFloat, sizing: SquareSizing) {
        pinchedSize = sizing.size(afterPinching: shownSquareSize, by: magnification)
    }

    private func finishPinching() {
        guard let size = pinchedSize else { return }

        store.send(.squareResized(size))
        pinchedSize = nil
    }
}
