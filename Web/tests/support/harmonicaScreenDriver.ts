import type { HarmonicaViewState } from '../../src/features/harmonica/harmonicaViewState.js'
import type { HarmonicaViewModel } from '../../src/features/harmonica/harmonicaViewModel.js'

const strip = { width: 1000, height: 100 }

export class HarmonicaScreenDriver {
    private shown: HarmonicaViewState = { kind: 'preparingSound' }

    constructor(readonly viewModel: HarmonicaViewModel) {
        viewModel.onStateChanged(state => { this.shown = state })
    }

    get state(): HarmonicaViewState {
        return this.shown
    }

    note(hole: number): string | undefined {
        if (this.shown.kind !== 'ready') return undefined

        return this.shown.playable.holes.find(each => each.id === hole)?.note
    }

    touchStrip(fractionFromLeftEdge: number, fractionAboveCentreLine: number): void {
        const location = {
            x: fractionFromLeftEdge * strip.width,
            y: (0.5 - fractionAboveCentreLine) * strip.height,
            force: null
        }
        this.viewModel.play([location], strip)
    }

    playTune(index: number): void {
        this.viewModel.playTheTune(index)
    }

    hideThePage(): void {
        this.viewModel.stopPlaying()
        this.viewModel.stopShapingTone()
    }
}
