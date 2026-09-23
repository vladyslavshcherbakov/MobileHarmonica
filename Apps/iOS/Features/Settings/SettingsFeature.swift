import ComposableArchitecture
import HarmonicaCore

@Reducer
struct SettingsFeature {
    @Dependency(\.settingsClient) private var settingsClient

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var settings: PlayerSettings
    }

    // MARK: - Action

    enum Action {
        case styleChosen(SettingsViewState.StyleChoice)
        case cuppingTurned(on: Bool)
        case squarePlaced(SquarePlacement)
        case squareResized(Double)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case settingsChanged(PlayerSettings)
        }
    }

    // MARK: - Public

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .styleChosen(let choice):
                return change(&state) { $0.style = Self.style(chosen: choice) }
            case .cuppingTurned(on: let isOn):
                return change(&state) { $0.isCuppingEnabled = isOn }
            case .squarePlaced(let placement):
                return change(&state) { $0.squarePlacement = placement }
            case .squareResized(let fraction):
                return change(&state) { $0.squareSize = SquareSize(clamping: fraction) }
            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Private

    private static func style(chosen choice: SettingsViewState.StyleChoice) -> PlayingStyle {
        switch choice {
        case .severalFingersSeveralNotes: .severalFingersSeveralNotes
        case .severalFingersOneNote: .severalFingersOneNote
        case .oneFingerSeveralNotes: .oneFingerSeveralNotes
        }
    }

    private func change(_ state: inout State, _ update: (inout PlayerSettings) -> Void) -> Effect<Action> {
        var updated = state.settings
        update(&updated)
        guard updated != state.settings else { return .none }

        state.settings = updated
        return .run { [settingsClient] send in
            settingsClient.save(updated)
            await send(.delegate(.settingsChanged(updated)))
        }
    }
}
