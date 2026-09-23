import Foundation
import HarmonicaCore

@MainActor
final class SettingsRepository {
    private static let styleKey = "settings.playingStyle"
    private static let cuppingKey = "settings.isCuppingEnabled"
    private static let placementKey = "settings.squarePlacement"
    private static let sizeKey = "settings.squareSize"

    private let defaults: UserDefaults
    private let log: LogProtocol

    // MARK: - Public

    nonisolated init(defaults: UserDefaults, log: LogProtocol) {
        self.defaults = defaults
        self.log = log
    }

    func settings() -> PlayerSettings {
        let firstLaunch = PlayerSettings.atFirstLaunch
        return PlayerSettings(
            style: stored(Self.styleKey, among: PlayingStyle.allCases, named: Self.name(of:)) ?? firstLaunch.style,
            isCuppingEnabled: stored(Self.cuppingKey, as: Bool.self) ?? firstLaunch.isCuppingEnabled,
            squarePlacement: stored(Self.placementKey, among: SquarePlacement.allCases, named: Self.name(of:))
                ?? firstLaunch.squarePlacement,
            squareSize: stored(Self.sizeKey, as: Double.self).map(SquareSize.init(clamping:)) ?? firstLaunch.squareSize
        )
    }

    func save(_ settings: PlayerSettings) {
        defaults.set(Self.name(of: settings.style), forKey: Self.styleKey)
        defaults.set(settings.isCuppingEnabled, forKey: Self.cuppingKey)
        defaults.set(Self.name(of: settings.squarePlacement), forKey: Self.placementKey)
        defaults.set(settings.squareSize.fraction, forKey: Self.sizeKey)
    }

    // MARK: - Private

    private static func name(of style: PlayingStyle) -> String {
        switch style {
        case .severalFingersSeveralNotes: "severalFingersSeveralNotes"
        case .severalFingersOneNote: "severalFingersOneNote"
        case .oneFingerSeveralNotes: "oneFingerSeveralNotes"
        }
    }

    private static func name(of placement: SquarePlacement) -> String {
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
