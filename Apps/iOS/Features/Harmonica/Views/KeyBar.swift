import SwiftUI

@MainActor
struct KeyBar: View {
    static let height: CGFloat = 44

    private static let clearOfTheScreenEdge: CGFloat = 20
    private static let controlHeight: CGFloat = 40
    private static let keyLabelWidth: CGFloat = 34
    private static let settingsButtonWidth: CGFloat = 52
    private static let demoButtonWidth: CGFloat = 64
    private static let cupBarWidth: CGFloat = 40
    private static let cupBarHeight: CGFloat = 6

    let playable: HarmonicaViewState.Playable
    let clearOf: Edge.Set
    let openSettings: @MainActor () -> Void
    @ObservedObject var viewModel: HarmonicaViewModel

    // MARK: - Public

    var body: some View {
        HStack {
            keyLabel
            keySlider
            cupIndicator
            demoControl
            settingsButton
        }
        .padding(.horizontal)
        .padding(.top, Self.clearOfTheScreenEdge)
        .safeAreaPadding(clearOf)
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

    @ViewBuilder
    private var cupIndicator: some View {
        if let cup = playable.cup {
            VStack(spacing: 2) {
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(white: 0.22))
                    Capsule().fill(Color.orange).frame(width: Self.cupBarWidth * cup.closed)
                }
                .frame(width: Self.cupBarWidth, height: Self.cupBarHeight)
                Text(cup.label)
                    .font(.caption2)
                    .foregroundStyle(Color(white: 0.5))
            }
        }
    }

    private var settingsButton: some View {
        Button(action: openSettings) {
            Image(systemName: "gearshape")
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(.orange)
        .frame(width: Self.settingsButtonWidth, height: Self.controlHeight)
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
