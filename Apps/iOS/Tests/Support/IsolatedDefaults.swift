import Foundation

final class IsolatedDefaults {
    let defaults: UserDefaults

    private let suiteName: String

    // MARK: - Public

    init() {
        let suiteName = "MobileHarmonicaTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            preconditionFailure("UserDefaults refused the suite \(suiteName)")
        }

        self.suiteName = suiteName
        self.defaults = defaults
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
