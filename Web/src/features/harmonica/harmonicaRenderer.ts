import type {
    HarmonicaViewState,
    HoleViewState,
    PlayableHarmonica
} from './harmonicaViewState.js'

export interface HarmonicaElements {
    readonly body: HTMLElement
    readonly keyLabel: HTMLElement
    readonly keySlider: HTMLInputElement
    readonly cupFill: HTMLElement
    readonly cupLabel: HTMLElement
    readonly mouthWidth: HTMLSelectElement
    readonly style: HTMLSelectElement
    readonly tunes: HTMLSelectElement
    readonly stopTune: HTMLElement
    readonly noteRow: HTMLElement
    readonly plates: HTMLElement
    readonly overbendLabel: HTMLElement
    readonly bendLabel: HTMLElement
    readonly vibratoLabel: HTMLElement
    readonly soundUnavailable: HTMLElement
}

export class HarmonicaRenderer {
    private readonly noteCells: NoteCell[] = []
    private readonly plates: Plate[] = []
    private drawn: PlayableHarmonica | null = null

    constructor(private readonly elements: HarmonicaElements) {}

    render(state: HarmonicaViewState): void {
        this.elements.body.classList.toggle('unavailable', state.kind === 'soundUnavailable')
        if (state.kind === 'soundUnavailable') {
            this.elements.soundUnavailable.textContent = state.text
            return
        }

        if (state.kind !== 'ready') return

        this.renderPlayable(state.playable)
    }

    private renderPlayable(playable: PlayableHarmonica): void {
        this.buildOnce(playable)
        this.renderHoles(playable.holes)
        this.renderKey(playable)
        this.renderCup(playable)
        this.renderControls(playable)
        this.renderToneShaping(playable)
        this.drawn = playable
    }

    private buildOnce(playable: PlayableHarmonica): void {
        if (this.drawn !== null) return

        for (const hole of playable.holes) {
            this.noteCells.push(addedNoteCell(this.elements.noteRow))
            this.plates.push(addedPlate(this.elements.plates, hole.label))
        }
        fill(this.elements.style, playable.style.choices.map(choice => [choice.id, choice.name]))
        fill(this.elements.mouthWidth, playable.mouth.widths.map(width => [String(width), `mouth ${width}`]))
        fill(
            this.elements.tunes,
            [['', playable.demo.label], ...playable.demo.tunes.map(tune => [String(tune.id), tune.name] as Choice)]
        )
    }

    private renderHoles(holes: readonly HoleViewState[]): void {
        holes.forEach((hole, index) => {
            const previous = this.drawn?.holes[index]
            const cell = this.noteCells[index]
            const plate = this.plates[index]
            if (cell === undefined || plate === undefined || sameHole(previous, hole)) return

            cell.name.textContent = hole.note
            cell.effect.textContent = hole.effect
            plate.top.classList.toggle('lit', hole.lit === 'top')
            plate.bottom.classList.toggle('lit', hole.lit === 'bottom')
            plate.number.classList.toggle('lit', hole.lit !== null)
        })
    }

    private renderKey(playable: PlayableHarmonica): void {
        if (this.drawn?.key.label === playable.key.label) return

        this.elements.keyLabel.textContent = playable.key.label
        this.elements.keySlider.max = String(playable.key.highestPosition)
        this.elements.keySlider.value = String(playable.key.position)
    }

    private renderCup(playable: PlayableHarmonica): void {
        if (this.drawn?.cup.closed === playable.cup.closed) return

        this.elements.cupFill.style.width = `${playable.cup.closed * 100}%`
        this.elements.cupLabel.textContent = playable.cup.label
    }

    private renderControls(playable: PlayableHarmonica): void {
        if (this.elements.style.value !== playable.style.chosen) {
            this.elements.style.value = playable.style.chosen
        }
        if (this.elements.mouthWidth.value !== String(playable.mouth.holesWide)) {
            this.elements.mouthWidth.value = String(playable.mouth.holesWide)
        }
        this.elements.mouthWidth.disabled = !playable.mouth.isAvailable
        if (this.drawn?.demo.isPlaying === playable.demo.isPlaying) return

        this.elements.stopTune.style.display = playable.demo.isPlaying ? 'block' : 'none'
        this.elements.tunes.style.display = playable.demo.isPlaying ? 'none' : 'block'
    }

    private renderToneShaping(playable: PlayableHarmonica): void {
        const shaping = playable.toneShaping
        if (this.drawn !== null && sameShaping(this.drawn, playable)) return

        this.elements.overbendLabel.textContent = shaping.overbendLabel
        this.elements.bendLabel.textContent = shaping.bendLabel
        this.elements.vibratoLabel.textContent = shaping.vibratoLabel
        this.elements.overbendLabel.classList.toggle('dim', !shaping.overbendIsAvailable)
        this.elements.bendLabel.classList.toggle('dim', !shaping.bendIsAvailable)
    }
}

interface NoteCell {
    readonly name: HTMLElement
    readonly effect: HTMLElement
}

interface Plate {
    readonly top: HTMLElement
    readonly bottom: HTMLElement
    readonly number: HTMLElement
}

type Choice = readonly [string, string]

function sameHole(previous: HoleViewState | undefined, hole: HoleViewState): boolean {
    return previous !== undefined
        && previous.note === hole.note
        && previous.effect === hole.effect
        && previous.lit === hole.lit
}

function sameShaping(drawn: PlayableHarmonica, playable: PlayableHarmonica): boolean {
    return drawn.toneShaping.overbendLabel === playable.toneShaping.overbendLabel
        && drawn.toneShaping.overbendIsAvailable === playable.toneShaping.overbendIsAvailable
        && drawn.toneShaping.bendIsAvailable === playable.toneShaping.bendIsAvailable
}

function addedNoteCell(row: HTMLElement): NoteCell {
    const cell = document.createElement('div')
    cell.className = 'noteCell'
    const name = document.createElement('span')
    name.className = 'noteName'
    const effect = document.createElement('span')
    effect.className = 'noteEffect'
    cell.append(name, effect)
    row.append(cell)
    return { name, effect }
}

function addedPlate(plates: HTMLElement, label: string): Plate {
    const plate = document.createElement('div')
    plate.className = 'plate'
    const top = document.createElement('div')
    top.className = 'plateTop'
    const bottom = document.createElement('div')
    bottom.className = 'plateBottom'
    const number = document.createElement('span')
    number.className = 'plateNumber'
    number.textContent = label
    plate.append(top, bottom, number)
    plates.append(plate)
    return { top, bottom, number }
}

function fill(select: HTMLSelectElement, choices: readonly Choice[]): void {
    select.replaceChildren(...choices.map(([value, name]) => {
        const option = document.createElement('option')
        option.value = value
        option.textContent = name
        return option
    }))
}
