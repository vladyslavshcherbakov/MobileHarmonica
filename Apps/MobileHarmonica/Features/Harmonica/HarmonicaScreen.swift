import SwiftUI

struct HarmonicaScreen: View {
    private static let holeSpacing: CGFloat = 6
    private static let centreLineThickness: CGFloat = 1
    private static let keyBarHeight: CGFloat = 44
    private static let keyLabelWidth: CGFloat = 34
    private static let fingerCircleDiameter: CGFloat = 56
    private static let fingerCircleLineWidth: CGFloat = 3

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HarmonicaViewModel
    @State private var fingerLocations: [CGPoint] = []

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

    private static func fingerMarks(at locations: [CGPoint], across size: CGSize) -> [FingerMark] {
        let positions = locations.map { position(of: $0, across: size) }
        let deciding = PositionOnHarmonica.topmost(of: positions)

        return positions.indices.compactMap { index in
            mark(index: index, at: locations[index], on: positions[index], deciding: deciding)
        }
    }

    private static func mark(
        index: Int,
        at location: CGPoint,
        on position: PositionOnHarmonica,
        deciding: PositionOnHarmonica?
    ) -> FingerMark? {
        guard Hole(at: position) != nil else { return nil }

        return FingerMark(id: index, location: location, decidesBreath: position == deciding)
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
            .overlay { fingerCircles(across: geometry.size) }
            .overlay { touchArea(across: geometry.size) }
        }
    }

    private var centreLine: some View {
        Rectangle()
            .fill(Color(white: 0.45))
            .frame(height: Self.centreLineThickness)
            .accessibilityHidden(true)
    }

    private func fingerCircles(across size: CGSize) -> some View {
        ForEach(Self.fingerMarks(at: fingerLocations, across: size)) { mark in
            Circle()
                .strokeBorder(
                    mark.decidesBreath ? Color.white : Color(white: 0.5),
                    lineWidth: Self.fingerCircleLineWidth
                )
                .frame(width: Self.fingerCircleDiameter, height: Self.fingerCircleDiameter)
                .position(mark.location)
        }
        .accessibilityHidden(true)
    }

    private func touchArea(across size: CGSize) -> some View {
        TouchArea { locations in
            fingerLocations = locations
            viewModel.play(at: locations.map { Self.position(of: $0, across: size) })
        }
    }

    @MainActor
    private func prepareOrSilence(for phase: ScenePhase) async {
        switch phase {
        case .active:
            await viewModel.prepareSound()
        default:
            viewModel.stopPlaying()
        }
    }
}

// MARK: - FingerMark

private struct FingerMark: Identifiable {
    let id: Int
    let location: CGPoint
    let decidesBreath: Bool
}
