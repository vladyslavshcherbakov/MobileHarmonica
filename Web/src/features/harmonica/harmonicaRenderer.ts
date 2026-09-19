import type {
    HarmonicaViewState,
    HoleViewState,
    PlayableHarmonica
} from './harmonicaViewState.js'

export interface HarmonicaElements {
    readonly body: HTMLElement
    readonly keyLabel: HTMLElement
    readonly keySlider: HTMLInputElement
    readonly notesPerFinger: HTMLSelectElement
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

const smallestNoteScale = 0.6

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

    fitTheNoteRow(): void {
        for (const cell of this.noteCells) fitToTheHole(cell)
    }

    private renderPlayable(playable: PlayableHarmonica): void {
        this.buildOnce(playable)
        this.renderHoles(playable.holes)
        this.renderKey(playable)
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
        fill(
            this.elements.notesPerFinger,
            playable.notesPerFinger.choices.map(choice => [String(choice.count), choice.name] as Choice)
        )
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
            fitToTheHole(cell)
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

    private renderControls(playable: PlayableHarmonica): void {
        if (this.elements.style.value !== playable.style.chosen) {
            this.elements.style.value = playable.style.chosen
        }
        if (this.elements.notesPerFinger.value !== String(playable.notesPerFinger.chosen)) {
            this.elements.notesPerFinger.value = String(playable.notesPerFinger.chosen)
        }
        this.elements.notesPerFinger.disabled = !playable.notesPerFinger.isAvailable
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

function fitToTheHole(cell: NoteCell): void {
    shrinkToFit(cell.name)
    shrinkToFit(cell.effect)
}

function shrinkToFit(text: HTMLElement): void {
    const room = text.parentElement?.clientWidth ?? 0
    if (room === 0) return

    const wanted = text.offsetWidth
    text.style.transform = wanted <= room ? '' : `scale(${Math.max(smallestNoteScale, room / wanted)})`
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
