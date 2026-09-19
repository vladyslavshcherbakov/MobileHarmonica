import SwiftUI

@MainActor
struct KeyBar: View {
    static let height: CGFloat = 44

    private static let clearOfTheScreenEdge: CGFloat = 20
    private static let controlHeight: CGFloat = 40
    private static let keyLabelWidth: CGFloat = 34
    private static let styleControlWidth: CGFloat = 180
    private static let demoButtonWidth: CGFloat = 64
    private static let cupBarWidth: CGFloat = 40
    private static let cupBarHeight: CGFloat = 6

    let playable: PlayableHarmonica
    @ObservedObject var viewModel: HarmonicaViewModel

    // MARK: - Public

    var body: some View {
        HStack {
            keyLabel
            keySlider
            cupIndicator
            playingStyleControl
            demoControl
        }
        .padding(.horizontal)
        .padding(.top, Self.clearOfTheScreenEdge)
        .safeAreaPadding(.leading)
        .frame(height: Self.height + Self.clearOfTheScreenEdge)
    }

    // MARK: - Private

    private var keyLabel: some View {
        Text(playable.key.label)
            .font(.headline)
            .monospaced()
            .foregroundStyle(.white)
            .frame(width: Self.keyLabelWidth, alignment: .leading)
    }

    private var keySlider: some View {
        Slider(
            value: Binding(get: { playable.key.position }, set: viewModel.changeKey(toPosition:)),
            in: 0...playable.key.highestPosition,
            step: 1
        )
        .tint(.orange)
        .frame(height: Self.controlHeight)
    }

    private var cupIndicator: some View {
        VStack(spacing: 2) {
            ZStack(alignment: .leading) {
                Capsule().fill(Color(white: 0.22))
                Capsule().fill(Color.orange).frame(width: Self.cupBarWidth * playable.cup.closed)
            }
            .frame(width: Self.cupBarWidth, height: Self.cupBarHeight)
            Text(playable.cup.label)
                .font(.caption2)
                .foregroundStyle(Color(white: 0.5))
        }
    }

    private var playingStyleControl: some View {
        Menu(playable.style.label) {
            ForEach(playable.style.choices) { choice in
                Button(choice.name) { viewModel.changeStyle(to: choice.id) }
            }
        }
        .lineLimit(1)
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.orange)
        .frame(width: Self.styleControlWidth, height: Self.controlHeight)
    }

    @ViewBuilder
    private var demoControl: some View {
        if playable.demo.isPlaying {
            Button(playable.demo.label, action: viewModel.stopTheTune)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.orange)
                .frame(width: Self.demoButtonWidth, height: Self.controlHeight)
        } else {
            tuneMenu
        }
    }

    private var tuneMenu: some View {
        Menu(playable.demo.label) {
            ForEach(playable.demo.tunes) { tune in
                Button(tune.name) { viewModel.playTheTune(at: tune.id) }
            }
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.orange)
        .frame(width: Self.demoButtonWidth, height: Self.controlHeight)
    }
}
