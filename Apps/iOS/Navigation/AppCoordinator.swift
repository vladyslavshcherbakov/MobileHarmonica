import Combine

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []

    func openSettings() {
        path.append(.settings)
    }
}
