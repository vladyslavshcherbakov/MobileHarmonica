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
        viewModel.send(.styleChosen(choice))
    }

    func turnCupping(on isOn: Bool) {
        viewModel.send(.cuppingTurned(on: isOn))
    }

    func placeShapingPad(_ placement: ShapingPadPlacement) {
        viewModel.send(.shapingPadPlaced(placement))
    }

    func moveTheSizeSlider(to fraction: Double) {
        viewModel.send(.shapingPadSizeSliderMoved(to: fraction))
    }
}
