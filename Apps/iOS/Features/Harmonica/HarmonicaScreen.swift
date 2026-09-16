import SwiftUI

struct HarmonicaScreen: View {
    private static let holeSpacing: CGFloat = 6
    private static let keyBarHeight: CGFloat = 44
    private static let keyLabelWidth: CGFloat = 34
    private static let fingerCircleDiameter: CGFloat = 56
    private static let fingerCircleLineWidth: CGFloat = 3
    private static let zoneWidthFraction: CGFloat = 0.22
    private static let zoneCornerRadius: CGFloat = 12
    private static let smallestZoneScale: CGFloat = 0.45
    private static let largestZoneScale: CGFloat = 2.0

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HarmonicaViewModel
    @State private var fingerLocations: [CGPoint] = []
    @State private var shapingLocations: [CGPoint] = []
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

    private static func position(of location: CGPoint, across size: CGSize) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: Double(location.x / size.width),
            fractionAboveCentreLine: Double((size.height / 2 - location.y) / size.height)
        )
    }

    private static func fingerMarks(at locations: [CGPoint], across size: CGSize) -> [FingerMark] {
        let positions = locations.map { position(of: $0, across: size) }
        let deciding = PositionOnHarmonica.topmost(of: positions.filter(\.isOnTheHarmonica))

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
        guard position.isOnTheHarmonica else { return nil }

        return FingerMark(id: index, location: location, decidesBreath: position == deciding)
    }

    private static func shapingMarks(at locations: [CGPoint]) -> [FingerMark] {
        let leading = topmostOnScreen(of: locations)

        return locations.indices.map { index in
            FingerMark(id: index, location: locations[index], decidesBreath: locations[index] == leading)
        }
    }

    private static func topmostOnScreen(of locations: [CGPoint]) -> CGPoint? {
        locations.min { $0.y < $1.y }
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
            GeometryReader { geometry in
                HStack(spacing: Self.holeSpacing) {
                    toneShapingZone(playable.toneShaping)
                        .frame(
                            width: Self.zoneSide(in: geometry.size, scaledBy: zoneScale),
                            height: Self.zoneSide(in: geometry.size, scaledBy: zoneScale)
                        )
                    holes(playable.holes)
                }
            }
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
        .safeAreaPadding(.leading)
        .frame(height: Self.keyBarHeight)
    }

    private func holes(_ holes: [HoleViewState]) -> some View {
        GeometryReader { geometry in
            HStack(spacing: Self.holeSpacing) {
                ForEach(holes) { hole in
                    HoleView(state: hole)
                }
            }
            .overlay { circles(Self.fingerMarks(at: fingerLocations, across: geometry.size)) }
            .overlay { holesTouchArea(across: geometry.size) }
        }
    }

    private func toneShapingZone(_ state: ToneShapingViewState) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: Self.zoneCornerRadius)
                .fill(Color(white: 0.13))
                .overlay(alignment: .leading) { zoneLabels(state) }
                .overlay { circles(Self.shapingMarks(at: shapingLocations)) }
                .overlay { shapingTouchArea(across: geometry.size) }
        }
        .accessibilityIdentifier("harmonica.toneShapingZone")
    }

    private func zoneLabels(_ state: ToneShapingViewState) -> some View {
        VStack(alignment: .leading) {
            Text(state.bendLabel)
                .foregroundStyle(state.bendIsAvailable ? Color(white: 0.55) : Color(white: 0.3))
            Spacer()
            Text(state.vibratoLabel)
                .foregroundStyle(Color(white: 0.55))
        }
        .font(.caption)
        .padding(8)
        .accessibilityHidden(true)
    }

    private func circles(_ marks: [FingerMark]) -> some View {
        ForEach(marks) { mark in
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

    private func holesTouchArea(across size: CGSize) -> some View {
        TouchArea { locations in
            fingerLocations = locations
            viewModel.play(at: locations.map { Self.position(of: $0, across: size) })
        }
    }

    private func shapingTouchArea(across size: CGSize) -> some View {
        TouchArea(
            touchesChanged: { locations in
                shapingLocations = locations
                shapeTone(from: locations, across: size)
            },
            pinched: resizeZone(by:)
        )
    }

    private func resizeZone(by magnification: CGFloat) {
        zoneScale = min(Self.largestZoneScale, max(Self.smallestZoneScale, zoneScale * magnification))
    }

    private func shapeTone(from locations: [CGPoint], across size: CGSize) {
        guard let leading = Self.topmostOnScreen(of: locations) else {
            viewModel.stopShapingTone()
            return
        }

        viewModel.shapeTone(
            bend: Double(leading.y / size.height),
            vibrato: Double(leading.x / size.width)
        )
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

// MARK: - FingerMark

private struct FingerMark: Identifiable {
    let id: Int
    let location: CGPoint
    let decidesBreath: Bool
}
