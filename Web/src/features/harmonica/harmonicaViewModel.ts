import type { CoreFinger, CoreState } from '../../core/coreState.js'
import type { HarmonicaCore } from '../../core/harmonicaCore.js'
import type { CoreAudio } from '../../core/coreState.js'
import type { Log } from '../../logging/log.js'
import type { HarmonicaPresenter } from './harmonicaPresenter.js'
import type { HarmonicaViewState, PlayingStyleChoice } from './harmonicaViewState.js'
import type { TuneEnding, TunePerformance } from './playTheTune.js'
import { PlayTheTune } from './playTheTune.js'

export class HarmonicaViewModel {
    private state: HarmonicaViewState = { kind: 'preparingSound' }
    private performance: TunePerformance | null = null
    private show: (state: HarmonicaViewState) => void = () => {}

    constructor(
        private readonly core: HarmonicaCore,
        private readonly audio: CoreAudio & { prepare(): Promise<void> },
        private readonly tunePlayer: PlayTheTune,
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
            this.present(this.core.start())
        } catch (failure) {
            this.publish(this.presenter.presentSoundUnavailable(describe(failure)))
        }
    }

    playAt(fingers: readonly CoreFinger[]): void {
        if (this.state.kind !== 'ready') return

        if (fingers.length > 0) this.stopTheTune()
        this.present(this.core.playAt(fingers))
    }

    changeKey(toPosition: number): void {
        if (this.state.kind !== 'ready') return

        this.present(this.core.changeKey(Math.round(toPosition)))
    }

    changeStyle(choice: PlayingStyleChoice): void {
        if (this.state.kind !== 'ready') return

        this.present(this.core.changeStyle(styleIndex(choice)))
    }

    changeNotesPerFinger(notes: number): void {
        if (this.state.kind !== 'ready') return

        this.present(this.core.changeMouth(notes))
    }

    playTheTune(index: number): void {
        if (this.state.kind !== 'ready') return

        this.stopTheTune()
        this.log.record(`the tune ${this.nameOfTune(index)} started`)
        this.performance = this.tunePlayer.play(index, harmonica => this.present(harmonica))
        void this.performance.finished
            .then(ending => this.tuneEnded(ending))
            .catch(failure => this.tuneFailed(failure))
    }

    stopTheTune(): void {
        this.performance?.cancel()
        this.performance = null
    }

    stopTheTuneAndSilence(): void {
        if (this.state.kind !== 'ready') return

        this.stopTheTune()
        this.present(this.core.stopPlaying(true))
    }

    shapeTone(pitch: number, vibrato: number): void {
        const harmonica = this.core.shapeTone(pitch, vibrato)
        if (this.state.kind !== 'ready') return

        this.present(harmonica)
    }

    stopShapingTone(): void {
        this.shapeTone(0, 0)
    }

    stopPlaying(): void {
        this.stopTheTune()
        const harmonica = this.core.stopPlaying(true)
        if (this.state.kind !== 'ready') return

        this.present(harmonica)
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

    private present(harmonica: CoreState): void {
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
    }
}

function describe(failure: unknown): string {
    return failure instanceof Error ? `${failure.name}: ${failure.message}` : String(failure)
}
