import type { HarmonicaDTO } from '../../core/harmonicaDTO.js'
import { holesWideOfTheContact } from '../../core/harmonicaDTO.js'
import type { HarmonicaCore } from '../../core/harmonicaCore.js'
import type { AudioEngine, AudioEngineError } from '../../core/audioEngine.js'
import { AudioEngineFailure } from '../../core/audioEngine.js'
import type { Log } from '../../logging/log.js'
import type { HarmonicaPresenter } from './harmonicaPresenter.js'
import type { AreaSize } from './touch/areaSize.js'
import type { Contact } from './touch/contact.js'
import type { FingerMark } from './touch/fingerMark.js'
import type { FingerMarksViewState, HarmonicaViewState, PlayingStyleChoice } from './harmonicaViewState.js'
import { isPlayingStyleChoice } from './harmonicaViewState.js'
import { SquareTouchMapper } from './touch/squareTouchMapper.js'
import { StripTouchMapper } from './touch/stripTouchMapper.js'
import type { TuneEnding, TunePerformance } from './playTheTuneUseCase.js'
import { PlayTheTuneUseCase } from './playTheTuneUseCase.js'

const startingNotesPerFinger = 1

export class HarmonicaViewModel {
    private state: HarmonicaViewState = { kind: 'preparingSound' }
    private performance: TunePerformance | null = null
    private notesPerFinger = startingNotesPerFinger
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

    async prepareSound(): Promise<void> {
        try {
            await this.audio.prepare()
        } catch (failure) {
            this.publish(this.presenter.presentSoundUnavailable(this.engineErrorOf(failure)))
            return
        }
        this.core.start()
        this.present(this.core.changeMouth(this.notesPerFinger))
    }

    play(contacts: readonly Contact[], across: AreaSize): void {
        if (!this.isReady('a touch on the strip')) return

        if (contacts.length > 0) this.stopTheTune()
        this.present(this.core.playAt(new StripTouchMapper(contacts, across).positions()))
    }

    marksOnTheStrip(contacts: readonly Contact[], across: AreaSize, drawn: FingerMarksViewState): FingerMark[] {
        return new StripTouchMapper(contacts, across).marks(drawn)
    }

    marksOnTheSquare(contacts: readonly Contact[], across: AreaSize): FingerMark[] {
        return new SquareTouchMapper(contacts, across).marks()
    }

    changeKey(toPosition: number): void {
        if (!this.isReady('a key change')) return

        this.present(this.core.changeKey(Math.round(toPosition)))
    }

    changeStyle(named: string): void {
        if (!this.isReady('a playing style')) return
        if (!isPlayingStyleChoice(named)) {
            console.assert(false, `the menu offered a playing style called ${named}`)
            this.log.record(`playing style ${named} was asked for and the page does not have it, nothing changed`)
            return
        }

        this.core.changeStyle(styleIndex(named))
        this.present(this.core.changeMouth(this.holesWideFor(named)))
    }

    changeNotesPerFinger(notes: number): void {
        if (!this.isReady('a number of notes per finger')) return

        this.notesPerFinger = notes
        this.present(this.core.changeMouth(notes))
    }

    playTheTune(index: number): void {
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

    stopTheTuneAndSilence(): void {
        if (!this.isReady('stopping the tune')) return

        this.stopTheTune()
        this.present(this.core.stopPlaying(true))
    }

    shapeTone(contacts: readonly Contact[], across: AreaSize): void {
        const shaping = new SquareTouchMapper(contacts, across).shaping()
        if (shaping === null) return this.stopShapingTone()

        this.shapeToneTo(shaping.pitch, shaping.vibrato)
    }

    stopShapingTone(): void {
        this.shapeToneTo(0, 0)
    }

    stopPlaying(): void {
        if (!this.isReady('stopping the sound')) return

        this.stopTheTune()
        this.present(this.core.stopPlaying(true))
    }

    private shapeToneTo(pitch: number, vibrato: number): void {
        if (!this.isReady('a touch on the square')) return

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
        this.publish(this.presenter.present(harmonica, this.performance !== null))
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
