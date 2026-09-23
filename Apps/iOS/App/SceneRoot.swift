import SwiftUI

struct SceneRoot: View {
    @StateObject private var coordinator = AppCoordinator()

    private let compositionRoot: CompositionRoot

    init(compositionRoot: CompositionRoot) {
        self.compositionRoot = compositionRoot
    }

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            compositionRoot.harmonicaScreen(openSettings: coordinator.openSettings)
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: AppRoute.self, destination: screen(for:))
        }
    }

    @ViewBuilder
    private func screen(for route: AppRoute) -> some View {
        switch route {
        case .settings: compositionRoot.settingsScreen()
        }
    }
}
