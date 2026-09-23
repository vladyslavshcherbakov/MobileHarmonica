import ComposableArchitecture

@Reducer
struct AppFeature {
    @Reducer
    enum Path {
        case settings(SettingsFeature)
    }

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var harmonica: HarmonicaFeature.State
        var path = StackState<Path.State>()
    }

    // MARK: - Action

    enum Action {
        case harmonica(HarmonicaFeature.Action)
        case path(StackActionOf<Path>)
    }

    // MARK: - Public

    var body: some ReducerOf<Self> {
        Scope(state: \.harmonica, action: \.harmonica) {
            HarmonicaFeature()
        }
        Reduce { state, action in
            switch action {
            case .harmonica(.delegate(.openSettings)):
                state.path.append(.settings(SettingsFeature.State(settings: state.harmonica.settings)))
                return .none
            case .path(.element(id: _, action: .settings(.delegate(.settingsChanged(let settings))))):
                return .send(.harmonica(.settingsChanged(settings)))
            case .harmonica, .path:
                return .none
            }
        }
        .forEach(\.path, action: \.path)
    }
}

// MARK: - AppFeature.Path.State + Equatable

extension AppFeature.Path.State: Equatable {}
