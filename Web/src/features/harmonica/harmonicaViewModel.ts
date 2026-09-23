import type { HarmonicaDTO } from '../../core/harmonicaDTO.js'
import { holesWideOfTheContact } from '../../core/harmonicaDTO.js'
import type { HarmonicaCore } from '../../core/harmonicaCore.js'
import type { AudioEngine, AudioEngineError } from '../../core/audioEngine.js'
import { AudioEngineFailure } from '../../core/audioEngine.js'
import type { Log } from '../../logging/log.js'
import type { HarmonicaAction } from './harmonicaAction.js'
import type { HarmonicaPresenter } from './harmonicaPresenter.js'
import type { AreaSize } from './touch/areaSize.js'
import type { Contact } from './touch/contact.js'
import type { FingerMark } from './touch/fingerMark.js'
import type { FingerMarksViewState, HarmonicaViewState, PlayingStyleChoice } from './harmonicaViewState.js'
import { isPlayingStyleChoice } from './harmonicaViewState.js'
import { ShapingPadTouchMapper } from './touch/shapingPadTouchMapper.js'
import { StripTouchMapper } from './touch/stripTouchMapper.js'
import type { TuneEnding, TunePerformance } from './playTheTuneUseCase.js'
import { PlayTheTuneUseCase } from './playTheTuneUseCase.js'

const startingNotesPerFinger = 1
const smallestShapingPadScale = 0.45
const largestShapingPadScale = 2

export class HarmonicaViewModel {
    private state: HarmonicaViewState = { kind: 'preparingSound' }
    private performance: TunePerformance | null = null
    private notesPerFinger = startingNotesPerFinger
    private shapingPadScale = 1
    private shownHarmonica: HarmonicaDTO | null = null
    private show: (state: HarmonicaViewState) => void = () => {}

    constructor(
        private readonly core: HarmonicaCore,
        private readonly audio: AudioEngine,
        private readonly tunePlayer: PlayTheTuneUseCase,
        private readonly presenter: HarmonicaPresenter,
        private readonly log: Log
    ) {}

    onStateChanged(show: (state: HarmonicaViewState) => void): void {
        this.show = show
        show(this.state)
    }

    send(action: HarmonicaAction): void {
        switch (action.kind) {
            case 'startButtonTapped': return void this.prepareSound()
            case 'pageHidden': return this.silence()
            case 'stripTouched': return this.play(action.contacts, action.across)
            case 'keySliderMoved': return this.changeKey(action.position)
            case 'styleChosen': return this.changeStyle(action.named)
            case 'notesPerFingerChosen': return this.changeNotesPerFinger(action.notes)
            case 'tuneChosen': return this.playTheTune(action.index)
            case 'stopTuneButtonTapped': return this.stopTheTuneAndSilence()
            case 'shapingPadTouched': return this.shapeTone(action.contacts, action.across)
            case 'shapingPadPinched': return this.resizeShapingPad(action.magnification)
        }
    }

    marksOnTheStrip(contacts: readonly Contact[], across: AreaSize, drawn: FingerMarksViewState): FingerMark[] {
        return new StripTouchMapper(contacts, across).marks(drawn)
    }

    marksOnTheShapingPad(contacts: readonly Contact[], across: AreaSize): FingerMark[] {
        return new ShapingPadTouchMapper(contacts, across).marks()
    }

    private async prepareSound(): Promise<void> {
        try {
            await this.audio.prepare()
        } catch (failure) {
            this.publish(this.presenter.presentSoundUnavailable(this.engineErrorOf(failure)))
            return
        }
        this.core.start()
        this.present(this.core.changeMouth(this.notesPerFinger))
    }

    private play(contacts: readonly Contact[], across: AreaSize): void {
        if (!this.isReady('a touch on the strip')) return

        if (contacts.length > 0) this.stopTheTune()
        this.present(this.core.playAt(new StripTouchMapper(contacts, across).positions()))
    }

    private changeKey(toPosition: number): void {
        if (!this.isReady('a key change')) return

        this.present(this.core.changeKey(Math.round(toPosition)))
    }

    private changeStyle(named: string): void {
        if (!this.isReady('a playing style')) return
        if (!isPlayingStyleChoice(named)) {
            console.assert(false, `the menu offered a playing style called ${named}`)
            this.log.record(`playing style ${named} was asked for and the page does not have it, nothing changed`)
            return
        }

        this.core.changeStyle(styleIndex(named))
        this.present(this.core.changeMouth(this.holesWideFor(named)))
    }

    private changeNotesPerFinger(notes: number): void {
        if (!this.isReady('a number of notes per finger')) return

        this.notesPerFinger = notes
        this.present(this.core.changeMouth(notes))
    }

    private playTheTune(index: number): void {
        if (!this.isReady('a tune')) return
        if (!this.offersTheTune(index)) {
            console.assert(false, `the menu offered tune ${index}, which the page does not have`)
            this.log.record(`tune ${index} was asked for and the page does not have it, nothing plays`)
            return
        }

        this.stopTheTune()
        this.log.record(`the tune ${this.nameOfTune(index)} started`)
        this.performance = this.tunePlayer.play(index, harmonica => this.present(harmonica))
        void this.performance.finished
            .then(ending => this.tuneEnded(ending))
            .catch(failure => this.tuneFailed(failure))
    }

    private stopTheTuneAndSilence(): void {
        if (!this.isReady('stopping the tune')) return

        this.stopTheTune()
        this.present(this.core.stopPlaying(true))
    }

    private shapeTone(contacts: readonly Contact[], across: AreaSize): void {
        const shaping = new ShapingPadTouchMapper(contacts, across).shaping()
        if (shaping === null) return this.stopShapingTone()

        this.shapeToneTo(shaping.pitch, shaping.vibrato)
    }

    private resizeShapingPad(magnification: number): void {
        if (!this.isReady('a pinch on the shaping pad') || this.shownHarmonica === null) return

        this.shapingPadScale = Math.min(
            largestShapingPadScale,
            Math.max(smallestShapingPadScale, this.shapingPadScale * magnification)
        )
        this.log.recordSample(`shaping pad scaled to ${this.shapingPadScale.toFixed(2)} of its natural side`)
        this.present(this.shownHarmonica)
    }

    private silence(): void {
        if (!this.isReady('silencing the harmonica')) return

        this.stopTheTune()
        this.present(this.core.stopPlaying(true))
        this.stopShapingTone()
    }

    private stopShapingTone(): void {
        this.shapeToneTo(0, 0)
    }

    private shapeToneTo(pitch: number, vibrato: number): void {
        if (!this.isReady('a touch on the shaping pad')) return

        this.present(this.core.shapeTone(pitch, vibrato))
    }

    private stopTheTune(): void {
        this.performance?.cancel()
        this.performance = null
    }

    private holesWideFor(style: PlayingStyleChoice): number {
        return style === 'oneFingerNotesByPressure' ? holesWideOfTheContact : this.notesPerFinger
    }

    private isReady(action: string): boolean {
        if (this.state.kind === 'ready') return true

        this.log.recordSample(`${action} arrived while the sound was ${this.state.kind}, nothing changed`)
        return false
    }

    private offersTheTune(index: number): boolean {
        return this.state.kind === 'ready' && this.state.playable.demo.tunes.some(tune => tune.id === index)
    }

    private engineErrorOf(failure: unknown): AudioEngineError {
        if (failure instanceof AudioEngineFailure) return failure.error

        console.assert(false, `the audio engine rejected with ${describe(failure)}, which it never should`)
        this.log.record(`the audio engine rejected with ${describe(failure)}, shown as an output that would not start`)
        return { kind: 'outputRefused' }
    }

    private nameOfTune(index: number): string {
        if (this.state.kind !== 'ready') return String(index)

        return this.state.playable.demo.tunes.find(tune => tune.id === index)?.name ?? String(index)
    }

    private tuneEnded(ending: TuneEnding): void {
        if (ending === 'stopped') return this.log.record('the tune was stopped')

        this.log.record('the tune ended')
        this.silenceTheTune()
    }

    private tuneFailed(failure: unknown): void {
        this.log.record(`the tune stopped: ${describe(failure)}`)
        this.silenceTheTune()
    }

    private silenceTheTune(): void {
        this.performance = null
        this.present(this.core.stopPlaying(true))
    }

    private present(harmonica: HarmonicaDTO): void {
        this.shownHarmonica = harmonica
        this.publish(this.presenter.present(harmonica, this.performance !== null, this.shapingPadScale))
    }

    private publish(state: HarmonicaViewState): void {
        this.state = state
        this.show(state)
    }
}

function styleIndex(choice: PlayingStyleChoice): number {
    switch (choice) {
        case 'severalFingersSeveralNotes': return 0
        case 'severalFingersOneNote': return 1
        case 'oneFingerSeveralNotes': return 2
        case 'oneFingerNotesByPressure': return 2
    }
}

function describe(failure: unknown): string {
    return failure instanceof Error ? `${failure.name}: ${failure.message}` : String(failure)
}
