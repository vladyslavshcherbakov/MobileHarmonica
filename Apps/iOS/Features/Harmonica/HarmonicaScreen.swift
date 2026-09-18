import SwiftUI

struct HarmonicaScreen: View {
    private static let holeSpacing: CGFloat = 6
    private static let keyBarHeight: CGFloat = 44
    private static let keyLabelWidth: CGFloat = 34
    private static let fingerCircleDiameter: CGFloat = 56
    private static let fingerCircleLineWidth: CGFloat = 3
    private static let styleControlWidth: CGFloat = 130
    private static let noteRowHeight: CGFloat = 30
    private static let zoneWidthFraction: CGFloat = 0.22
    private static let zoneCornerRadius: CGFloat = 12
    private static let smallestZoneScale: CGFloat = 0.45
    private static let largestZoneScale: CGFloat = 2.0

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel: HarmonicaViewModel
    @State private var fingerTouches: [FingerTouch] = []
    @State private var shapingTouches: [FingerTouch] = []
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

    private static func labelShade(isAvailable: Bool) -> Color {
        isAvailable ? Color(white: 0.55) : Color(white: 0.3)
    }

    private static func zoneSide(in size: CGSize, scaledBy scale: CGFloat) -> CGFloat {
        min(size.height, min(size.height, size.width * Self.zoneWidthFraction) * scale)
    }

    private static func position(of touch: FingerTouch, across size: CGSize) -> PositionOnHarmonica {
        PositionOnHarmonica(
            fractionFromLeftEdge: Double(touch.location.x / size.width),
            fractionAboveCentreLine: Double((size.height / 2 - touch.location.y) / size.height),
            fractionCoveredEitherSide: Double(touch.radius / size.width)
        )
    }

    private static func fingerMarks(at touches: [FingerTouch], across size: CGSize, isMouth: Bool) -> [FingerMark] {
        let positions = touches.map { position(of: $0, across: size) }
        let deciding = PositionOnHarmonica.topmost(of: positions.filter(\.isOnTheHarmonica))

        return positions.indices
            .filter { isDrawn(positions[$0], deciding: deciding, isMouth: isMouth) }
            .map { mark(index: $0, at: touches[$0], decidesBreath: positions[$0] == deciding, isMouth: isMouth) }
    }

    private static func isDrawn(
        _ position: PositionOnHarmonica,
        deciding: PositionOnHarmonica?,
        isMouth: Bool
    ) -> Bool {
        isMouth ? position == deciding : position.isOnTheHarmonica
    }

    private static func mark(index: Int, at touch: FingerTouch, decidesBreath: Bool, isMouth: Bool) -> FingerMark {
        FingerMark(
            id: index,
            location: touch.location,
            diameter: isMouth ? 2 * touch.radius : fingerCircleDiameter,
            decidesBreath: decidesBreath
        )
    }

    private static func shapingMarks(at touches: [FingerTouch]) -> [FingerMark] {
        let leading = topmostOnScreen(of: touches)

        return touches.indices.map { index in
            FingerMark(
                id: index,
                location: touches[index].location,
                diameter: fingerCircleDiameter,
                decidesBreath: touches[index].location == leading
            )
        }
    }

    private static func topmostOnScreen(of touches: [FingerTouch]) -> CGPoint? {
        touches.map(\.location).min { $0.y < $1.y }
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
            keyBar(playable)
            GeometryReader { geometry in
                HStack(spacing: Self.holeSpacing) {
                    toneShapingZone(playable.toneShaping)
                        .frame(
                            width: Self.zoneSide(in: geometry.size, scaledBy: zoneScale),
                            height: Self.zoneSide(in: geometry.size, scaledBy: zoneScale)
                        )
                    holes(playable.holes, isMouth: playable.style.isMouth)
                }
            }
        }
    }

    private func keyBar(_ playable: PlayableHarmonica) -> some View {
        HStack {
            Text(playable.key.label)
                .font(.headline)
                .monospaced()
                .foregroundStyle(.white)
                .frame(width: Self.keyLabelWidth, alignment: .leading)
            Slider(
                value: Binding(get: { playable.key.position }, set: viewModel.changeKey(toPosition:)),
                in: 0...playable.key.highestPosition,
                step: 1
            )
            .tint(.orange)
            playingStyleControl(playable.style)
            overbendStyleControl(playable.overbendStyle)
        }
        .padding(.horizontal)
        .safeAreaPadding(.leading)
        .frame(height: Self.keyBarHeight)
    }

    private func playingStyleControl(_ style: PlayingStyleViewState) -> some View {
        Picker("", selection: Binding(get: { style.isMouth }, set: viewModel.changeStyle(toMouth:))) {
            Text(style.fingersLabel).tag(false)
            Text(style.mouthLabel).tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: Self.styleControlWidth)
    }

    private func overbendStyleControl(_ style: OverbendStyleViewState) -> some View {
        Picker("", selection: Binding(get: { style.isSnap }, set: viewModel.changeOverbendStyle(toSnap:))) {
            Text(style.smoothLabel).tag(false)
            Text(style.snapLabel).tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: Self.styleControlWidth)
    }

    private func holes(_ holes: [HoleViewState], isMouth: Bool) -> some View {
        VStack(spacing: 0) {
            noteRow(holes)
            GeometryReader { geometry in
                HStack(spacing: Self.holeSpacing) {
                    ForEach(holes) { hole in
                        HoleView(state: hole)
                    }
                }
                .overlay {
                    circles(Self.fingerMarks(at: fingerTouches, across: geometry.size, isMouth: isMouth))
                }
                .overlay { holesTouchArea(across: geometry.size) }
            }
        }
    }

    private func noteRow(_ holes: [HoleViewState]) -> some View {
        HStack(spacing: Self.holeSpacing) {
            ForEach(holes) { hole in
                soundingNote(hole)
            }
        }
        .frame(height: Self.noteRowHeight)
    }

    private func soundingNote(_ hole: HoleViewState) -> some View {
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

    private func toneShapingZone(_ state: ToneShapingViewState) -> some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: Self.zoneCornerRadius)
                .fill(Color(white: 0.13))
                .overlay(alignment: .leading) { pitchLabels(state) }
                .overlay(alignment: .bottomTrailing) { vibratoLabel(state) }
                .overlay { circles(Self.shapingMarks(at: shapingTouches)) }
                .overlay { shapingTouchArea(across: geometry.size) }
        }
    }

    private func pitchLabels(_ state: ToneShapingViewState) -> some View {
        VStack(alignment: .leading) {
            Text(state.overbendLabel)
                .foregroundStyle(Self.labelShade(isAvailable: state.overbendIsAvailable))
            Spacer()
            Text(state.bendLabel)
                .foregroundStyle(Self.labelShade(isAvailable: state.bendIsAvailable))
        }
        .font(.caption)
        .padding(8)
    }

    private func vibratoLabel(_ state: ToneShapingViewState) -> some View {
        Text(state.vibratoLabel)
            .font(.caption)
            .foregroundStyle(Self.labelShade(isAvailable: true))
            .padding(8)
    }

    private func circles(_ marks: [FingerMark]) -> some View {
        ForEach(marks) { mark in
            Circle()
                .strokeBorder(
                    mark.decidesBreath ? Color.white : Color(white: 0.5),
                    lineWidth: Self.fingerCircleLineWidth
                )
                .frame(width: mark.diameter, height: mark.diameter)
                .position(mark.location)
        }
    }

    private func holesTouchArea(across size: CGSize) -> some View {
        TouchArea { touches in
            fingerTouches = touches
            viewModel.play(at: touches.map { Self.position(of: $0, across: size) })
        }
    }

    private func shapingTouchArea(across size: CGSize) -> some View {
        TouchArea(
            touchesChanged: { touches in
                shapingTouches = touches
                shapeTone(from: touches, across: size)
            },
            pinched: resizeZone(by:)
        )
    }

    private func resizeZone(by magnification: CGFloat) {
        zoneScale = min(Self.largestZoneScale, max(Self.smallestZoneScale, zoneScale * magnification))
    }

    private func shapeTone(from touches: [FingerTouch], across size: CGSize) {
        guard let leading = Self.topmostOnScreen(of: touches) else {
            viewModel.stopShapingTone()
            return
        }

        viewModel.shapeTone(
            pitch: 1 - 2 * Double(leading.y / size.height),
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
    let diameter: CGFloat
    let decidesBreath: Bool
}
