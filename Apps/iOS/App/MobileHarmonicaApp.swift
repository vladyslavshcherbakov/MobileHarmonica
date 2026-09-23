import Foundation
import HarmonicaCore
import SwiftUI

@main
struct MobileHarmonicaApp: App {
    private static let logCategory = "harmonica"
    private static let subsystemWithoutABundleIdentifier = "com.vladyslavshcherbakov.mobileharmonica"

    private let compositionRoot: CompositionRoot

    init() {
        let log = Self.harmonicaLog()
        compositionRoot = CompositionRoot(
            audioEngine: SampledAudioEngine(log: log),
            tilt: DeviceTilt(),
            defaults: .standard,
            log: log,
            locale: .current,
            writtenTunes: [BundledScoreRepository(tuning: RichterTuning(), log: log).first()].compactMap { $0 }
        )
    }

    var body: some Scene {
        WindowGroup {
            SceneRoot(compositionRoot: compositionRoot)
        }
    }

    private static func harmonicaLog() -> TimestampedLog {
        guard let identifier = Bundle.main.bundleIdentifier else {
            assertionFailure("the app bundle has no CFBundleIdentifier")
            let log = TimestampedLog(subsystem: subsystemWithoutABundleIdentifier, category: logCategory)
            log.record("the app bundle has no CFBundleIdentifier, logging under \(subsystemWithoutABundleIdentifier)")
            return log
        }

        return TimestampedLog(subsystem: identifier, category: logCategory)
    }
}
