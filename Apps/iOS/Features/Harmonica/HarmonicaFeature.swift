import ComposableArchitecture
import HarmonicaCore

@Reducer
struct HarmonicaFeature {
    private enum CancelID {
        case preparation
        case tilt
    }

    @Dependency(\.instrument) private var instrument
    @Dependency(\.tilt) private var tilt
    @Dependency(\.settingsClient) private var settingsClient

    // MARK: - State

    @ObservableState
    struct State: Equatable {
        var sound: Sound = .preparing
        var settings: PlayerSettings
        var isOnScreen = false
    }

    // MARK: - Sound

    enum Sound: Equatable {
        case preparing
        case ready
        case unavailable(String)
    }

    // MARK: - Action

    enum Action {
        case sceneBecameActive
        case sceneLeftTheForeground
        case appeared
        case disappeared
        case soundPrepared
        case soundFailed(AudioEngineError)
        case squareResized(SquareSize)
        case settingsButtonTapped
        case settingsChanged(PlayerSettings)
        case delegate(Delegate)

        @CasePathable
        enum Delegate {
            case openSettings
        }
    }

    // MARK: - Public

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .sceneBecameActive:
                return prepare(adopting: state.settings)
            case .sceneLeftTheForeground:
                return silence()
            case .appeared:
                state.isOnScreen = true
                return followTheTilt(state)
            case .disappeared:
                state.isOnScreen = false
                return silence()
            case .soundPrepared:
                state.sound = .ready
                return followTheTilt(state)
            case .soundFailed(let failure):
                state.sound = .unavailable(HarmonicaPresenter.unavailableText(because: failure))
                return .cancel(id: CancelID.tilt)
            case .squareResized(let size):
                state.settings.squareSize = size
                return save(state.settings)
            case .settingsButtonTapped:
                return .send(.delegate(.openSettings))
            case .settingsChanged(let settings):
                state.settings = settings
                return .merge(adopt(settings), followTheTilt(state))
            case .delegate:
                return .none
            }
        }
    }

    // MARK: - Private

    private func prepare(adopting settings: PlayerSettings) -> Effect<Action> {
        .run { [instrument] send in
            do throws(AudioEngineError) {
                try await instrument.prepare(settings)
                await send(.soundPrepared)
            } catch {
                await send(.soundFailed(error))
            }
        }
        .cancellable(id: CancelID.preparation, cancelInFlight: true)
    }

    private func followTheTilt(_ state: State) -> Effect<Action> {
        guard state.sound == .ready, state.isOnScreen, state.settings.isCuppingEnabled else {
            return .cancel(id: CancelID.tilt)
        }

        return .run { [instrument, tilt] _ in
            for await leaning in await tilt.tiltToTheRight() {
                await instrument.cupHands(leaning)
            }
        }
        .cancellable(id: CancelID.tilt, cancelInFlight: true)
    }

    private func silence() -> Effect<Action> {
        .merge(
            .cancel(id: CancelID.tilt),
            .run { [instrument] _ in await instrument.silence() }
        )
    }

    private func adopt(_ settings: PlayerSettings) -> Effect<Action> {
        .run { [instrument] _ in await instrument.adopt(settings) }
    }

    private func save(_ settings: PlayerSettings) -> Effect<Action> {
        .run { [settingsClient] _ in settingsClient.save(settings) }
    }
}
