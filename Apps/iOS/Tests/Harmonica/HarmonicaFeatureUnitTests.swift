import ComposableArchitecture
import HarmonicaCore
import XCTest
@testable import MobileHarmonica

@MainActor
final class HarmonicaFeatureUnitTests: XCTestCase {
    // MARK: - Tests

    func test_harmonicaScreen_whenTheOutputRefusesToStart_saysSoundIsUnavailable() async {
        let store = TestStore(initialState: HarmonicaFeature.State(settings: .atFirstLaunch)) {
            HarmonicaFeature()
        } withDependencies: {
            $0.instrument.prepare = { (_: PlayerSettings) async throws(AudioEngineError) -> Void in
                throw .outputRefused
            }
        }

        await store.send(.sceneBecameActive)

        await store.receive(\.soundFailed) {
            $0.sound = .unavailable("Sound is unavailable: the audio output would not start.")
        }
    }

    func test_harmonicaScreen_whenItAppearsWithCuppingOff_leavesThePhoneUnwatched() async {
        var settings = PlayerSettings.atFirstLaunch
        settings.isCuppingEnabled = false
        let store = TestStore(initialState: HarmonicaFeature.State(sound: .ready, settings: settings)) {
            HarmonicaFeature()
        }

        await store.send(.appeared) { $0.isOnScreen = true }
    }
}
