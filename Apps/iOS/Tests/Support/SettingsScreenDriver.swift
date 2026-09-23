import ComposableArchitecture
@testable import MobileHarmonica

@MainActor
final class SettingsScreenDriver {
    private let store: StoreOf<AppFeature>
    private let screen: StackElementID

    // MARK: - Public

    init(store: StoreOf<AppFeature>) {
        guard let screen = store.path.ids.last else {
            preconditionFailure("the settings screen is not open")
        }

        self.store = store
        self.screen = screen
    }

    var state: SettingsViewState {
        guard case .settings(let settings)? = store.path[id: screen] else {
            preconditionFailure("the settings screen was closed")
        }

        return SettingsPresenter().present(settings.settings)
    }

    func chooseStyle(_ choice: SettingsViewState.StyleChoice) async {
        await send(.styleChosen(choice))
    }

    func turnCupping(on isOn: Bool) async {
        await send(.cuppingTurned(on: isOn))
    }

    func placeSquare(_ placement: SquarePlacement) async {
        await send(.squarePlaced(placement))
    }

    func moveTheSizeSlider(to fraction: Double) async {
        await send(.squareResized(fraction))
    }

    // MARK: - Private

    private func send(_ action: SettingsFeature.Action) async {
        await store.send(.path(.element(id: screen, action: .settings(action)))).finish()
    }
}
