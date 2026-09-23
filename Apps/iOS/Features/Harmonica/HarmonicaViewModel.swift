import Combine
import CoreGraphics
import HarmonicaCore

@MainActor
final class HarmonicaViewModel: ObservableObject {
    @Published private(set) var state: HarmonicaViewState = .preparingSound

    private let playHarmonica: PlayHarmonicaUseCase
    private let playScore: PlayScoreUseCase
    private let tilt: TiltProtocol
    private let settingsRepository: SettingsRepository
    private let tunes: [Score]
    private let presenter: HarmonicaPresenter
    private let log: LogProtocol
    private let pauseBeforeATune: Duration
    private let openSettings: @MainActor () -> Void
    private var settings: PlayerSettings
    private var isOnScreen = false
    private var soundPreparation: Task<Void, Never>?
    private var tiltFollowing: Task<Void, Never>?
    private var tunePerformance: Task<Void, Never>?
    private var playingTune: Int?
    private var settingsSubscription: AnyCancellable?

    // MARK: - Public

    init(
        playHarmonica: PlayHarmonicaUseCase,
        playScore: PlayScoreUseCase,
        tilt: TiltProtocol,
        settingsRepository: SettingsRepository,
        tunes: [Score],
        presenter: HarmonicaPresenter,
        log: LogProtocol,
        pauseBeforeATune: Duration,
        openSettings: @escaping @MainActor () -> Void
    ) {
        self.playHarmonica = playHarmonica
        self.playScore = playScore
        self.tilt = tilt
        self.settingsRepository = settingsRepository
        self.tunes = tunes
        self.presenter = presenter
        self.log = log
        self.pauseBeforeATune = pauseBeforeATune
        self.openSettings = openSettings
        settings = settingsRepository.settings()
        settingsSubscription = settingsRepository.savedSettings.sink { [weak self] savedSettings in self?.adopt(savedSettings) }
    }

    deinit {
        soundPreparation?.cancel()
        tiltFollowing?.cancel()
        tunePerformance?.cancel()
    }

    func send(_ action: HarmonicaAction) {
        switch action {
        case .appBecameActive:
            prepareSound()
        case .appLeftTheForeground:
            silence()
        case .screenAppeared:
            isOnScreen = true
            followTheTiltIfItShould()
        case .screenDisappeared:
            isOnScreen = false
            silence()
            followTheTiltIfItShould()
        case .stripTouched(let touches, across: let size):
            play(touches, across: size)
        case .keySliderMoved(toPosition: let position):
            changeKey(toPosition: position)
        case .tuneChosen(at: let index):
            playTheTune(at: index)
        case .stopTuneButtonTapped:
            stopTheTune()
        case .shapingPadTouched(let touches, across: let size):
            shapeTone(with: touches, across: size)
        case .shapingPadPinched(by: let magnification, within: let area):
            resizeShapingPad(by: magnification, within: area)
        case .settingsButtonTapped:
            openSettings()
        }
    }

    func marksOnTheStrip(
        for touches: [FingerTouch],
        across size: CGSize,
        style: HarmonicaViewState.FingerMarks
    ) -> [FingerMark] {
        StripTouchMapper(touches, across: size).marks(drawn: style)
    }

    func marksOnTheShapingPad(for touches: [FingerTouch], across size: CGSize) -> [FingerMark] {
        ShapingPadTouchMapper(touches, across: size).marks
    }

    // MARK: - Private

    private var reasonNotToFollowTheTilt: String? {
        guard case .ready = state else { return "the sound is not ready" }
        guard isOnScreen else { return "the harmonica is not on screen" }
        guard settings.isCuppingEnabled else { return "cupping is off in the settings" }

        return nil
    }

    private func prepareSound() {
        soundPreparation?.cancel()
        soundPreparation = Task { [weak self] in await self?.prepareTheEngine() }
    }

    private func play(_ touches: [FingerTouch], across size: CGSize) {
        guard isReady(toTake: "a touch on the strip") else { return }

        if !touches.isEmpty {
            stopTheScore()
        }
        show(playHarmonica.play(at: StripTouchMapper(touches, across: size).positions))
    }

    private func changeKey(toPosition position: Double) {
        guard isReady(toTake: "a key change") else { return }

        let key = HarmonicaKey(nearestSliderPosition: Int(position.rounded()))
        show(playHarmonica.changeKey(to: key))
    }

    private func playTheTune(at index: Int) {
        guard isReady(toTake: "a tune") else { return }
        guard tunes.indices.contains(index) else {
            assertionFailure("the menu offered tune \(index) of \(tunes.count)")
            log.record("tune \(index) was asked for, there are \(tunes.count), nothing plays")
            return
        }

        stopTheScore()
        playingTune = index
        tunePerformance = perform(tunes[index])
        show(playHarmonica.harmonica)
    }

    private func stopTheTune() {
        guard isReady(toTake: "stopping the tune") else { return }

        stopTheScore()
        show(playHarmonica.stopPlaying(.ringsDown))
    }

    private func shapeTone(with touches: [FingerTouch], across size: CGSize) {
        let shapingPad = ShapingPadTouchMapper(touches, across: size)
        guard let shaping = shapingPad.pitchShaping, let vibrato = shapingPad.vibrato else {
            stopShapingTone()
            return
        }

        shapeTone(shaping, vibrato: vibrato)
    }

    private func resizeShapingPad(by magnification: CGFloat, within area: CGSize) {
        guard isReady(toTake: "a pinch on the shaping pad") else { return }

        var settingsAfterThePinch = settings
        settingsAfterThePinch.shapingPadSize = ShapingPadSizing(in: area)
            .size(afterPinching: settings.shapingPadSize, by: magnification)
        guard settingsAfterThePinch != settings else { return }

        log.recordSample("shaping pad resized to \(settingsAfterThePinch.shapingPadSize.fraction) of its range")
        settingsRepository.save(settingsAfterThePinch)
    }

    private func stopShapingTone() {
        shapeTone(.rest, vibrato: .off)
    }

    private func prepareTheEngine() async {
        do throws(AudioEngineError) {
            _ = try await playHarmonica.prepare()
            show(harmonica(adopting: settings))
        } catch {
            publish(presenter.presentSoundUnavailable(because: error))
        }
        followTheTiltIfItShould()
    }

    private func adopt(_ savedSettings: PlayerSettings) {
        settings = savedSettings
        followTheTiltIfItShould()
        guard isReady(toTake: "the settings") else { return }

        show(harmonica(adopting: savedSettings))
    }

    private func harmonica(adopting settings: PlayerSettings) -> Harmonica {
        let harmonicaInTheChosenStyle = playHarmonica.changeStyle(to: settings.style)
        guard !settings.isCuppingEnabled else { return harmonicaInTheChosenStyle }

        return playHarmonica.cupHands(to: .open)
    }

    private func followTheTiltIfItShould() {
        guard let reason = reasonNotToFollowTheTilt else {
            startFollowingTheTilt()
            return
        }

        stopFollowingTheTilt(because: reason)
    }

    private func startFollowingTheTilt() {
        guard tiltFollowing == nil else { return }

        log.record("following the lean of the phone")
        let leaningsOfThePhone = tilt.tiltToTheRight()
        tiltFollowing = Task { [weak self] in
            for await leaning in leaningsOfThePhone {
                self?.cupHands(to: CupDepth(clamping: leaning))
            }
        }
    }

    private func stopFollowingTheTilt(because reason: String) {
        guard let tiltFollowing else { return }

        tiltFollowing.cancel()
        self.tiltFollowing = nil
        log.record("the lean of the phone is no longer followed: \(reason)")
    }

    private func silence() {
        guard isReady(toTake: "silencing the harmonica") else { return }

        stopTheScore()
        show(playHarmonica.stopPlaying(.ringsDown))
        stopShapingTone()
    }

    private func perform(_ tune: Score) -> Task<Void, Never> {
        Task { [weak self, playScore, pauseBeforeATune] in
            do {
                try await Task.sleep(for: pauseBeforeATune)
            } catch {
                return
            }

            await playScore.play(tune) { harmonica in self?.show(harmonica) }
            guard !Task.isCancelled else { return }

            self?.finishTheTune()
        }
    }

    private func finishTheTune() {
        tunePerformance = nil
        playingTune = nil
        show(playHarmonica.stopPlaying(.ringsDown))
    }

    private func shapeTone(_ shaping: PitchShaping, vibrato: VibratoDepth) {
        guard isReady(toTake: "a touch on the shaping pad") else { return }

        show(playHarmonica.shapeTone(shaping, vibrato: vibrato))
    }

    private func cupHands(to cup: CupDepth) {
        guard isReady(toTake: "a lean of the phone") else { return }

        show(playHarmonica.cupHands(to: cup))
    }

    private func isReady(toTake action: String) -> Bool {
        guard case .ready = state else {
            log.recordSample("\(action) arrived while the sound was not ready, nothing changed")
            return false
        }

        return true
    }

    private func stopTheScore() {
        tunePerformance?.cancel()
        tunePerformance = nil
        playingTune = nil
    }

    private func show(_ harmonica: Harmonica) {
        publish(presenter.present(harmonica, settings: settings, playingTune: playingTune))
    }

    private func publish(_ updated: HarmonicaViewState) {
        guard updated != state else { return }

        state = updated
    }
}
