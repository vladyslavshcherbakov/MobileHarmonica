import type { Harmonica } from '../../domain/instrument/harmonica.js'
import { keyAtNearestSliderPosition } from '../../domain/instrument/harmonicaKey.js'
import { mouthWidth } from '../../domain/playing/mouthWidth.js'
import { cupDepth } from '../../domain/playing/cupDepth.js'
import { pitchShaping } from '../../domain/playing/pitchShaping.js'
import type { PlayingStyle } from '../../domain/playing/playingStyle.js'
import type { PositionOnHarmonica } from '../../domain/playing/positionOnHarmonica.js'
import { vibratoDepth } from '../../domain/playing/vibratoDepth.js'
import type { Score } from '../../domain/scores/score.js'
import type { PlayHarmonica } from '../../domain/useCases/playHarmonica.js'
import type { PlayScore, ScorePerformance } from '../../domain/useCases/playScore.js'
import type { Tilt } from '../../domain/protocols/tilt.js'
import type { HarmonicaPresenter } from './harmonicaPresenter.js'
import type { HarmonicaViewState, PlayingStyleChoice } from './harmonicaViewState.js'

export class HarmonicaViewModel {
    private state: HarmonicaViewState = { kind: 'preparingSound' }
    private performance: ScorePerformance | null = null
    private show: (state: HarmonicaViewState) => void = () => {}

    constructor(
        private readonly playHarmonica: PlayHarmonica,
        private readonly playScore: PlayScore,
        private readonly tilt: Tilt,
        private readonly tunes: readonly Score[],
        private readonly presenter: HarmonicaPresenter
    ) {}

    onStateChanged(show: (state: HarmonicaViewState) => void): void {
        this.show = show
        show(this.state)
    }

    async prepareSound(): Promise<void> {
        try {
            this.present(await this.playHarmonica.prepare())
        } catch (failure) {
            this.publish(this.presenter.presentSoundUnavailable(describe(failure)))
        }
    }

    async followTheTilt(): Promise<void> {
        await this.tilt.requestAccess()
        this.tilt.followTheLean(leaning => this.cupHands(leaning))
    }

    playAt(positions: readonly PositionOnHarmonica[]): void {
        if (this.state.kind !== 'ready') return

        if (positions.length > 0) this.stopTheScore()
        this.present(this.playHarmonica.playAt(positions))
    }

    changeKey(toPosition: number): void {
        if (this.state.kind !== 'ready') return

        this.present(this.playHarmonica.changeKey(keyAtNearestSliderPosition(Math.round(toPosition))))
    }

    changeStyle(choice: PlayingStyleChoice): void {
        if (this.state.kind !== 'ready') return

        this.present(this.playHarmonica.changeStyle(styleChosen(choice)))
    }

    changeMouthWidth(holesWide: number): void {
        if (this.state.kind !== 'ready') return

        this.present(this.playHarmonica.changeMouthWidth(mouthWidth(holesWide)))
    }

    playTheTune(index: number): void {
        const tune = this.tunes[index]
        if (this.state.kind !== 'ready' || tune === undefined) return

        this.stopTheScore()
        this.performance = this.playScore.play(tune, harmonica => this.present(harmonica))
        void this.performance.finished.then(() => this.tuneFinished())
    }

    stopTheTune(): void {
        if (this.state.kind !== 'ready') return

        this.stopTheScore()
        this.present(this.playHarmonica.stopPlaying('ringsDown'))
    }

    shapeTone(pitch: number, vibrato: number): void {
        const harmonica = this.playHarmonica.shapeTone(pitchShaping(pitch), vibratoDepth(vibrato))
        if (this.state.kind !== 'ready') return

        this.present(harmonica)
    }

    stopShapingTone(): void {
        this.shapeTone(0, 0)
    }

    stopPlaying(): void {
        this.stopTheScore()
        const harmonica = this.playHarmonica.stopPlaying('ringsDown')
        if (this.state.kind !== 'ready') return

        this.present(harmonica)
    }

    private tuneFinished(): void {
        this.performance = null
        this.present(this.playHarmonica.stopPlaying('ringsDown'))
    }

    private cupHands(leaning: number): void {
        const harmonica = this.playHarmonica.cupHands(cupDepth(leaning))
        if (this.state.kind !== 'ready') return

        this.present(harmonica)
    }

    private stopTheScore(): void {
        this.performance?.cancel()
        this.performance = null
    }

    private present(harmonica: Harmonica): void {
        this.publish(this.presenter.present(harmonica, this.performance !== null))
    }

    private publish(state: HarmonicaViewState): void {
        this.state = state
        this.show(state)
    }
}

function describe(failure: unknown): string {
    return failure instanceof Error ? `${failure.name}: ${failure.message}` : String(failure)
}

function styleChosen(choice: PlayingStyleChoice): PlayingStyle {
    switch (choice) {
        case 'severalFingersSeveralNotes': return 'severalFingersSeveralNotes'
        case 'severalFingersOneNote': return 'severalFingersOneNote'
        case 'oneFingerSeveralNotes': return 'oneFingerSeveralNotes'
    }
}
