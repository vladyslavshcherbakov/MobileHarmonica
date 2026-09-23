enum SettingsAction {
    case styleChosen(SettingsViewState.StyleChoice)
    case cuppingTurned(on: Bool)
    case shapingPadPlaced(ShapingPadPlacement)
    case shapingPadSizeSliderMoved(to: Double)
}
