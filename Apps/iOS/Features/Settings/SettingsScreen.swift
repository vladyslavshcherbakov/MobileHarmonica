import SwiftUI

@MainActor
struct SettingsScreen: View {
    @StateObject private var viewModel: SettingsViewModel

    // MARK: - Public

    init(viewModel: @autoclosure @escaping @MainActor () -> SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: MainActor.assumeIsolated { viewModel() })
    }

    var body: some View {
        Form {
            styleControl
            cuppingControl
            placementControl
            sizeControl
        }
        .navigationTitle(viewModel.state.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .tint(.orange)
    }

    // MARK: - Private

    private var state: SettingsViewState {
        viewModel.state
    }

    private var styleControl: some View {
        Picker(
            state.style.label,
            selection: Binding(get: { state.style.chosen }, set: { viewModel.send(.styleChosen($0)) })
        ) {
            ForEach(state.style.choices) { option in
                Text(option.name).tag(option.id)
            }
        }
    }

    private var cuppingControl: some View {
        Toggle(
            state.cupping.label,
            isOn: Binding(get: { state.cupping.isOn }, set: { viewModel.send(.cuppingTurned(on: $0)) })
        )
    }

    private var placementControl: some View {
        LabeledContent(state.shapingPadPlacement.label) {
            Picker(
                state.shapingPadPlacement.label,
                selection: Binding(
                    get: { state.shapingPadPlacement.chosen },
                    set: { viewModel.send(.shapingPadPlaced($0)) }
                )
            ) {
                ForEach(state.shapingPadPlacement.choices) { option in
                    Text(option.name).tag(option.id)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var sizeControl: some View {
        LabeledContent(state.shapingPadSize.label) {
            Slider(
                value: Binding(
                    get: { state.shapingPadSize.fraction },
                    set: { viewModel.send(.shapingPadSizeSliderMoved(to: $0)) }
                ),
                in: 0...1
            )
        }
    }
}
