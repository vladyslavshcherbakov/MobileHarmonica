import SwiftUI

struct SceneRoot: View {
    @StateObject private var coordinator = AppCoordinator()

    private let compositionRoot: CompositionRoot

    init(compositionRoot: CompositionRoot) {
        self.compositionRoot = compositionRoot
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            compositionRoot.harmonicaScreen()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
