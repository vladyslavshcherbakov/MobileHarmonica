import type { HarmonicaViewState } from '../../src/features/harmonica/harmonicaViewState.js'
import type { HarmonicaViewModel } from '../../src/features/harmonica/harmonicaViewModel.js'
import { waitUntil } from './waitUntil.js'

const strip = { width: 1000, height: 100 }
const shapingPad = { width: 100, height: 100 }

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

    async open(): Promise<void> {
        this.viewModel.send({ kind: 'startButtonTapped' })
        await waitUntil(() => this.shown.kind !== 'preparingSound')
    }

    touchStrip(fractionFromLeftEdge: number, fractionAboveCentreLine: number): void {
        const contact = {
            x: fractionFromLeftEdge * strip.width,
            y: (0.5 - fractionAboveCentreLine) * strip.height,
            force: null
        }
        this.viewModel.send({ kind: 'stripTouched', contacts: [contact], across: strip })
    }

    touchShapingPad(heightAboveTheMiddle: number, vibrato: number): void {
        const contact = {
            x: vibrato * shapingPad.width,
            y: ((1 - heightAboveTheMiddle) / 2) * shapingPad.height,
            force: null
        }
        this.viewModel.send({ kind: 'shapingPadTouched', contacts: [contact], across: shapingPad })
    }

    playTune(index: number): void {
        this.viewModel.send({ kind: 'tuneChosen', index })
    }

    hideThePage(): void {
        this.viewModel.send({ kind: 'pageHidden' })
    }
}
