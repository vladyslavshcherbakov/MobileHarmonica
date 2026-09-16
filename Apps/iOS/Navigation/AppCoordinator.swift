import Combine

final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []
}
