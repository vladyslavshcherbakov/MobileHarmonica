import SwiftUI

@main
struct MobileHarmonicaApp: App {
    private let compositionRoot = CompositionRoot()

    var body: some Scene {
        WindowGroup {
            SceneRoot(compositionRoot: compositionRoot)
        }
    }
}
