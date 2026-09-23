import ComposableArchitecture
import SwiftUI

struct AppScreen: View {
    @Bindable var store: StoreOf<AppFeature>
    let harmonica: HarmonicaViewModel

    var body: some View {
        NavigationStack(path: $store.scope(\.path, action: \.path)) {
            HarmonicaScreen(store: store.scope(state: \.harmonica, action: \.harmonica), viewModel: harmonica)
                .toolbar(.hidden, for: .navigationBar)
        } destination: { store in
            switch store.case {
            case .settings(let store):
                SettingsScreen(store: store)
            }
        }
    }
}
