@testable import MobileHarmonica

@MainActor
final class SettingsScreenDriver {
    let viewModel: SettingsViewModel

    // MARK: - Public

    init(_ viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }

    var state: SettingsViewState {
        viewModel.state
    }

    func chooseStyle(_ choice: SettingsViewState.StyleChoice) {
        viewModel.chooseStyle(choice)
    }

    func turnCupping(on isOn: Bool) {
        viewModel.turnCupping(on: isOn)
    }

    func placeSquare(_ placement: SquarePlacement) {
        viewModel.placeSquare(placement)
    }

    func moveTheSizeSlider(to fraction: Double) {
        viewModel.resizeSquare(to: fraction)
    }
}
