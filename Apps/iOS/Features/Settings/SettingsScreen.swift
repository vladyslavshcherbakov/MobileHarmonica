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
        .tint(.orange)
    }

    // MARK: - Private

    private var state: SettingsViewState {
        viewModel.state
    }

    private var styleControl: some View {
        Picker(
            state.style.label,
            selection: Binding(get: { state.style.chosen }, set: viewModel.chooseStyle)
        ) {
            ForEach(state.style.choices) { option in
                Text(option.name).tag(option.id)
            }
        }
    }

    private var cuppingControl: some View {
        Toggle(
            state.cupping.label,
            isOn: Binding(get: { state.cupping.isOn }, set: viewModel.turnCupping(on:))
        )
    }

    private var placementControl: some View {
        LabeledContent(state.squarePlacement.label) {
            Picker(
                state.squarePlacement.label,
                selection: Binding(get: { state.squarePlacement.chosen }, set: viewModel.placeSquare)
            ) {
                ForEach(state.squarePlacement.choices) { option in
                    Text(option.name).tag(option.id)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var sizeControl: some View {
        LabeledContent(state.squareSize.label) {
            Slider(
                value: Binding(get: { state.squareSize.fraction }, set: viewModel.resizeSquare(to:)),
                in: 0...1
            )
        }
    }
}
