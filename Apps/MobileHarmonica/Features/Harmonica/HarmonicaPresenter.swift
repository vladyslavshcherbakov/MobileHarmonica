import Foundation

struct HarmonicaPresenter {
    private static let soundUnavailableText = "Sound is unavailable."

    private let holeLabels: [String]

    init(locale: Locale) {
        holeLabels = Hole.allCases.map { $0.number.formatted(.number.locale(locale)) }
    }

    func present(soundingHole: Hole?) -> HarmonicaViewState {
        .ready(holes(soundingHole: soundingHole))
    }

    func presentSoundUnavailable() -> HarmonicaViewState {
        .soundUnavailable(Self.soundUnavailableText)
    }

    private func holes(soundingHole: Hole?) -> [HoleViewState] {
        zip(Hole.allCases, holeLabels).map { hole, label in
            HoleViewState(id: hole.number, label: label, isSounding: hole == soundingHole)
        }
    }
}
