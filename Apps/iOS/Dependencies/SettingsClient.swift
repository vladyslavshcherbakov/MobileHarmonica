import ComposableArchitecture
import HarmonicaCore

struct SettingsClient: Sendable {
    var save: @Sendable (PlayerSettings) -> Void

    static func storing(in repository: SettingsRepository, log: LogProtocol) -> Self {
        SettingsClient(
            save: { settings in
                repository.save(settings)
                log.record("settings saved: \(settings)")
            }
        )
    }
}

// MARK: - SettingsClient + TestDependencyKey

extension SettingsClient: TestDependencyKey {
    static let testValue = SettingsClient(
        save: { _ in assertionFailure("SettingsClient.save is not provided") }
    )
}

// MARK: - DependencyValues + SettingsClient

extension DependencyValues {
    var settingsClient: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue }
    }
}
