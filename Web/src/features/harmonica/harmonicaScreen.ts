import type { AreaSize } from './touch/areaSize.js'
import type { Contact } from './touch/contact.js'
import { FingerCircles } from './touch/fingerCircles.js'
import { fillTheScreen, runsAsAnApp, theScreenCanBeFilled } from './page/fullScreen.js'
import { HarmonicaRenderer } from './harmonicaRenderer.js'
import type { FingerMarksViewState, HarmonicaViewState } from './harmonicaViewState.js'
import type { HarmonicaViewModel } from './harmonicaViewModel.js'
import { element } from './page/pageElement.js'
import { TouchArea } from './touch/touchArea.js'

const shapingPadWidthFraction = 0.22
const loadingLabel = 'loading the reeds'

export class HarmonicaScreen {
    private readonly renderer: HarmonicaRenderer
    private readonly stripCircles: FingerCircles
    private readonly shapingPadCircles: FingerCircles
    private readonly strip: TouchArea
    private readonly shapingPad: TouchArea
    private marks: FingerMarksViewState = { width: { kind: 'holesWide', holes: 2 }, drawsOnlyTheDecidingFinger: false }
    private shapingPadScale: number | null = null

    constructor(private readonly viewModel: HarmonicaViewModel) {
        this.renderer = new HarmonicaRenderer({
            body: document.body,
            keyLabel: element('keyLabel'),
            keySlider: element<HTMLInputElement>('keySlider'),
            notesPerFinger: element<HTMLSelectElement>('notesPerFinger'),
            style: element<HTMLSelectElement>('style'),
            tunes: element<HTMLSelectElement>('tunes'),
            stopTune: element('stopTune'),
            noteRow: element('noteRow'),
            plates: element('plates'),
            pitchLabel: element('pitchLabel'),
            vibratoLabel: element('vibratoLabel'),
            soundUnavailable: element('soundUnavailable')
        })
        this.stripCircles = new FingerCircles(element('stripMarks'))
        this.shapingPadCircles = new FingerCircles(element('shapingPadMarks'))
        this.strip = new TouchArea(element('plates'), { changed: contacts => this.touchTheStrip(contacts) })
        this.shapingPad = new TouchArea(element('shapingPad'), {
            changed: contacts => this.touchTheShapingPad(contacts),
            pinched: magnification => this.viewModel.send({ kind: 'shapingPadPinched', magnification })
        })
    }

    start(): void {
        this.viewModel.onStateChanged(state => this.show(state))
        this.listenToTheControls()
        this.listenToTheViewport()
        this.layOutTheShapingPad()
    }

    private show(state: HarmonicaViewState): void {
        if (state.kind !== 'preparingSound') document.body.classList.remove('preparing')
        if (state.kind === 'ready') {
            this.marks = state.playable.fingerMarks
            this.resizeTheShapingPad(state.playable.shapingPad.scale)
        }

        this.renderer.render(state)
    }

    private listenToTheControls(): void {
        element<HTMLInputElement>('keySlider').addEventListener('input', event => {
            this.viewModel.send({ kind: 'keySliderMoved', position: Number((event.target as HTMLInputElement).value) })
        })
        element<HTMLSelectElement>('style').addEventListener('change', event => {
            this.viewModel.send({ kind: 'styleChosen', named: (event.target as HTMLSelectElement).value })
        })
        element<HTMLSelectElement>('notesPerFinger').addEventListener('change', event => {
            this.viewModel.send({ kind: 'notesPerFingerChosen', notes: Number((event.target as HTMLSelectElement).value) })
        })
        element<HTMLSelectElement>('tunes').addEventListener('change', event => {
            const chosen = event.target as HTMLSelectElement
            if (chosen.value !== '') this.viewModel.send({ kind: 'tuneChosen', index: Number(chosen.value) })

            chosen.value = ''
        })
        element('stopTune').addEventListener('click', () => this.viewModel.send({ kind: 'stopTuneButtonTapped' }))
        this.listenToTheFullScreenButton()
        element('startButton').addEventListener('click', () => this.startSound())
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) this.viewModel.send({ kind: 'pageHidden' })
        })
        window.addEventListener('pagehide', () => this.viewModel.send({ kind: 'pageHidden' }))
    }

    private listenToTheViewport(): void {
        const relaid = () => this.layOutTheShapingPad()
        window.addEventListener('resize', relaid)
        window.addEventListener('orientationchange', relaid)
        window.visualViewport?.addEventListener('resize', relaid)
        document.addEventListener('fullscreenchange', relaid)
        document.addEventListener('webkitfullscreenchange', relaid)
    }

    private listenToTheFullScreenButton(): void {
        if (!theScreenCanBeFilled()) {
            if (!runsAsAnApp()) document.body.classList.add('cannotFillTheScreen')

            return
        }

        document.body.classList.add('canFillTheScreen')
        element('fullScreen').addEventListener('click', () => void fillTheScreen())
        element('fillTheScreenHint').addEventListener('click', () => {
            document.body.classList.remove('askedToFillTheScreen')
        })
    }

    private startSound(): void {
        const button = element<HTMLButtonElement>('startButton')
        button.disabled = true
        button.textContent = loadingLabel
        this.viewModel.send({ kind: 'startButtonTapped' })
    }

    private touchTheStrip(contacts: readonly Contact[]): void {
        const plates = sizeOf(element('plates'))
        this.viewModel.send({ kind: 'stripTouched', contacts, across: plates })
        this.stripCircles.draw(this.viewModel.marksOnTheStrip(contacts, plates, this.marks))
    }

    private touchTheShapingPad(contacts: readonly Contact[]): void {
        const shapingPad = sizeOf(element('shapingPad'))
        this.viewModel.send({ kind: 'shapingPadTouched', contacts, across: shapingPad })
        this.shapingPadCircles.draw(this.viewModel.marksOnTheShapingPad(contacts, shapingPad))
    }

    private resizeTheShapingPad(scale: number): void {
        if (scale === this.shapingPadScale) return

        this.shapingPadScale = scale
        this.layOutTheShapingPad()
    }

    private layOutTheShapingPad(): void {
        const viewport = window.visualViewport
        if (viewport !== null) {
            document.documentElement.style.setProperty('--appHeight', `${viewport.height}px`)
        }

        const instrument = element('instrument')
        const natural = Math.min(instrument.clientHeight, instrument.clientWidth * shapingPadWidthFraction)
        const side = Math.min(instrument.clientHeight, natural * (this.shapingPadScale ?? 1))
        document.documentElement.style.setProperty('--shapingPadSide', `${Math.round(side)}px`)
        this.strip.refreshBounds()
        this.shapingPad.refreshBounds()
        this.renderer.fitTheNoteRow()
    }
}

function sizeOf(area: HTMLElement): AreaSize {
    return { width: area.clientWidth, height: area.clientHeight }
}
