import SwiftUI

struct HarmonicaScreen: View {
    private static let holeSpacing: CGFloat = 6
    private static let centreLineThickness: CGFloat = 1
    private static let keyBarHeight: CGFloat = 44
    private static let keyLabelWidth: CGFloat = 34

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

    private static func position(of location: CGPoint, across size: CGSize) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: Double(location.x / size.width),
            fractionAboveCentreLine: Double((size.height / 2 - location.y) / size.height)
        )
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
                .accessibilityIdentifier("harmonica.soundUnavailable")
        }
    }

    private func playableHarmonica(_ playable: PlayableHarmonica) -> some View {
        VStack(spacing: 0) {
            keyBar(playable.key)
            holes(playable.holes)
        }
    }

    private func keyBar(_ key: KeyViewState) -> some View {
        HStack {
            Text(key.label)
                .font(.headline)
                .monospaced()
                .foregroundStyle(.white)
                .frame(width: Self.keyLabelWidth, alignment: .leading)
                .accessibilityIdentifier("harmonica.key")
            Slider(
                value: Binding(get: { key.position }, set: viewModel.changeKey(toPosition:)),
                in: 0...key.highestPosition,
                step: 1
            )
            .tint(.orange)
            .accessibilityIdentifier("harmonica.keySlider")
            .accessibilityLabel(key.label)
        }
        .padding(.horizontal)
        .frame(height: Self.keyBarHeight)
    }

    private func holes(_ holes: [HoleViewState]) -> some View {
        GeometryReader { geometry in
            HStack(spacing: Self.holeSpacing) {
                ForEach(holes) { hole in
                    HoleView(state: hole)
                }
            }
            .overlay { centreLine }
            .overlay { touchArea(across: geometry.size) }
        }
    }

    private var centreLine: some View {
        Rectangle()
            .fill(Color(white: 0.45))
            .frame(height: Self.centreLineThickness)
            .accessibilityHidden(true)
    }

    private func touchArea(across size: CGSize) -> some View {
        TouchArea { [viewModel] locations in
            viewModel.play(at: locations.map { Self.position(of: $0, across: size) })
        }
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
