import ComposableArchitecture
import SwiftUI

@MainActor
struct SettingsScreen: View {
    @State private var sizeWhileDragging: Double?

    private let store: StoreOf<SettingsFeature>

    // MARK: - Public

    init(store: StoreOf<SettingsFeature>) {
        self.store = store
    }

    var body: some View {
        Form {
            styleControl
            cuppingControl
            placementControl
            sizeControl
        }
        .navigationTitle(state.title)
        .tint(.orange)
    }

    // MARK: - Private

    private var state: SettingsViewState {
        SettingsPresenter().present(store.settings)
    }

    private var styleControl: some View {
        Picker(
            state.style.label,
            selection: Binding(get: { state.style.chosen }, set: { store.send(.styleChosen($0)) })
        ) {
            ForEach(state.style.choices) { option in
                Text(option.name).tag(option.id)
            }
        }
    }

    private var cuppingControl: some View {
        Toggle(
            state.cupping.label,
            isOn: Binding(get: { state.cupping.isOn }, set: { store.send(.cuppingTurned(on: $0)) })
        )
    }

    private var placementControl: some View {
        LabeledContent(state.squarePlacement.label) {
            Picker(
                state.squarePlacement.label,
                selection: Binding(get: { state.squarePlacement.chosen }, set: { store.send(.squarePlaced($0)) })
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
                value: Binding(get: { sizeWhileDragging ?? state.squareSize.fraction }, set: { sizeWhileDragging = $0 }),
                in: 0...1,
                onEditingChanged: { isEditing in finishResizing(isEditing: isEditing) }
            )
        }
    }

    private func finishResizing(isEditing: Bool) {
        guard !isEditing, let fraction = sizeWhileDragging else { return }

        store.send(.squareResized(fraction))
        sizeWhileDragging = nil
    }
}
