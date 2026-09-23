import Combine
import Foundation
import HarmonicaCore

@MainActor
final class SettingsRepository {
    private static let styleKey = "settings.playingStyle"
    private static let cuppingKey = "settings.isCuppingEnabled"
    private static let placementKey = "settings.shapingPadPlacement"
    private static let sizeKey = "settings.shapingPadSize"

    private let defaults: UserDefaults
    private let log: LogProtocol
    private let savedSettingsSubject = PassthroughSubject<PlayerSettings, Never>()

    // MARK: - Public

    init(defaults: UserDefaults, log: LogProtocol) {
        self.defaults = defaults
        self.log = log
    }

    var savedSettings: AnyPublisher<PlayerSettings, Never> {
        savedSettingsSubject.eraseToAnyPublisher()
    }

    func settings() -> PlayerSettings {
        let firstLaunch = PlayerSettings.atFirstLaunch
        return PlayerSettings(
            style: stored(Self.styleKey, among: PlayingStyle.allCases, named: Self.name(of:)) ?? firstLaunch.style,
            isCuppingEnabled: stored(Self.cuppingKey, as: Bool.self) ?? firstLaunch.isCuppingEnabled,
            shapingPadPlacement: stored(Self.placementKey, among: ShapingPadPlacement.allCases, named: Self.name(of:))
                ?? firstLaunch.shapingPadPlacement,
            shapingPadSize: stored(Self.sizeKey, as: Double.self).map(ShapingPadSize.init(clamping:))
                ?? firstLaunch.shapingPadSize
        )
    }

    func save(_ settings: PlayerSettings) {
        defaults.set(Self.name(of: settings.style), forKey: Self.styleKey)
        defaults.set(settings.isCuppingEnabled, forKey: Self.cuppingKey)
        defaults.set(Self.name(of: settings.shapingPadPlacement), forKey: Self.placementKey)
        defaults.set(settings.shapingPadSize.fraction, forKey: Self.sizeKey)
        savedSettingsSubject.send(settings)
    }

    // MARK: - Private

    private static func name(of style: PlayingStyle) -> String {
        switch style {
        case .severalFingersSeveralNotes: "severalFingersSeveralNotes"
        case .severalFingersOneNote: "severalFingersOneNote"
        case .oneFingerSeveralNotes: "oneFingerSeveralNotes"
        }
    }

    private static func name(of placement: ShapingPadPlacement) -> String {
        switch placement {
        case .left: "left"
        case .right: "right"
        }
    }

    private func stored<Value>(_ key: String, among values: [Value], named name: (Value) -> String) -> Value? {
        guard let storedName = stored(key, as: String.self) else { return nil }
        guard let value = values.first(where: { name($0) == storedName }) else {
            log.record("stored \(key) is \(storedName), which this build does not know, the first launch value is used")
            return nil
        }

        return value
    }

    private func stored<Value>(_ key: String, as type: Value.Type) -> Value? {
        guard let stored = defaults.object(forKey: key) else { return nil }
        guard let value = stored as? Value else {
            log.record("stored \(key) is \(stored), not a \(type), the first launch value is used")
            return nil
        }

        return value
    }
}
