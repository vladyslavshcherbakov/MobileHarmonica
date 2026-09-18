import SwiftUI

struct HarmonicaScreen: View {
    private static let zoneWidthFraction: CGFloat = 0.22
    private static let smallestZoneScale: CGFloat = 0.45
    private static let largestZoneScale: CGFloat = 2.0

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HarmonicaViewModel
    @State private var zoneScale: CGFloat = 1

    // MARK: - Public

    init(viewModel: @autoclosure @escaping () -> HarmonicaViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .leading)
            .background(Color.black.ignoresSafeArea())
            .task(id: scenePhase) {
                await prepareOrSilence(for: scenePhase)
            }
    }

    // MARK: - Private

    private static func zoneSide(in size: CGSize, scaledBy scale: CGFloat) -> CGFloat {
        min(size.height, min(size.height, size.width * Self.zoneWidthFraction) * scale)
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

    private func playableHarmonica(_ playable: PlayableHarmonica) -> some View {
        VStack(spacing: 0) {
            KeyBar(playable: playable, viewModel: viewModel)
            GeometryReader { geometry in
                HStack(spacing: HarmonicaStrip.holeSpacing) {
                    ToneShapingZone(
                        state: playable.toneShaping,
                        pinched: resizeZone(by:),
                        viewModel: viewModel
                    )
                    .frame(
                        width: Self.zoneSide(in: geometry.size, scaledBy: zoneScale),
                        height: Self.zoneSide(in: geometry.size, scaledBy: zoneScale)
                    )
                    HarmonicaStrip(
                        holes: playable.holes,
                        isMouth: playable.style.isMouth,
                        viewModel: viewModel
                    )
                }
            }
        }
    }

    private func resizeZone(by magnification: CGFloat) {
        zoneScale = min(Self.largestZoneScale, max(Self.smallestZoneScale, zoneScale * magnification))
    }

    @MainActor
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
