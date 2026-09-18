import SwiftUI

struct KeyBar: View {
    static let height: CGFloat = 44

    private static let keyLabelWidth: CGFloat = 34
    private static let styleControlWidth: CGFloat = 180
    private static let demoButtonWidth: CGFloat = 64

    let playable: PlayableHarmonica
    @ObservedObject var viewModel: HarmonicaViewModel

    // MARK: - Public

    var body: some View {
        HStack {
            keyLabel
            keySlider
            playingStyleControl
            demoControl
        }
        .padding(.horizontal)
        .safeAreaPadding(.leading)
        .frame(height: Self.height)
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
    }

    private var playingStyleControl: some View {
        Menu(playable.style.label) {
            ForEach(playable.style.choices) { choice in
                Button(choice.name) { viewModel.changeStyle(to: choice.id) }
            }
        }
        .lineLimit(1)
        .buttonStyle(.bordered)
        .tint(.orange)
        .frame(width: Self.styleControlWidth)
    }

    @ViewBuilder
    private var demoControl: some View {
        if playable.demo.isPlaying {
            Button(playable.demo.label, action: viewModel.stopTheTune)
                .buttonStyle(.bordered)
                .tint(.orange)
                .frame(width: Self.demoButtonWidth)
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
        .tint(.orange)
        .frame(width: Self.demoButtonWidth)
    }
}
