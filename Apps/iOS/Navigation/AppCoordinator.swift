import Combine

final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []

    func openSettings() {
        path.append(.settings)
    }
}
