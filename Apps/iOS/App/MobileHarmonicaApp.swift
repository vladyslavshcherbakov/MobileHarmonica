import Foundation
import SwiftUI

@main
struct MobileHarmonicaApp: App {
    private let compositionRoot: CompositionRoot

    init() {
        let log = TimestampedLog(subsystem: Self.bundleIdentifier(), category: "harmonica")
        compositionRoot = CompositionRoot(
            audioEngine: SampledAudioEngine(log: log),
            tilt: DeviceTilt(),
            log: log
        )
    }

    var body: some Scene {
        WindowGroup {
            SceneRoot(compositionRoot: compositionRoot)
        }
    }

    private static func bundleIdentifier() -> String {
        guard let identifier = Bundle.main.bundleIdentifier else {
            preconditionFailure("the app bundle has no CFBundleIdentifier")
        }
        return identifier
    }
}
