import type { AreaSize } from './touch/areaSize.js'
import type { Contact } from './touch/contact.js'
import { FingerCircles } from './touch/fingerCircles.js'
import { fillTheScreen, runsAsAnApp, theScreenCanBeFilled } from './page/fullScreen.js'
import { HarmonicaRenderer } from './harmonicaRenderer.js'
import type { FingerMarksViewState, HarmonicaViewState } from './harmonicaViewState.js'
import type { HarmonicaViewModel } from './harmonicaViewModel.js'
import { element } from './page/pageElement.js'
import { TouchArea } from './touch/touchArea.js'

const zoneWidthFraction = 0.22
const smallestZoneScale = 0.45
const largestZoneScale = 2
const loadingLabel = 'loading the reeds'

export class HarmonicaScreen {
    private readonly renderer: HarmonicaRenderer
    private readonly stripCircles: FingerCircles
    private readonly zoneCircles: FingerCircles
    private readonly strip: TouchArea
    private readonly zone: TouchArea
    private marks: FingerMarksViewState = { width: { kind: 'holesWide', holes: 2 }, drawsOnlyTheDecidingFinger: false }
    private zoneScale = 1

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
            overbendLabel: element('overbendLabel'),
            bendLabel: element('bendLabel'),
            vibratoLabel: element('vibratoLabel'),
            soundUnavailable: element('soundUnavailable')
        })
        this.stripCircles = new FingerCircles(element('stripMarks'))
        this.zoneCircles = new FingerCircles(element('zoneMarks'))
        this.strip = new TouchArea(element('plates'), { changed: contacts => this.playAt(contacts) })
        this.zone = new TouchArea(element('zone'), {
            changed: contacts => this.shapeTone(contacts),
            pinched: magnification => this.resizeZone(magnification)
        })
    }

    start(): void {
        this.viewModel.onStateChanged(state => this.show(state))
        this.listenToTheControls()
        this.listenToTheViewport()
        this.layOutTheZone()
    }

    private show(state: HarmonicaViewState): void {
        if (state.kind === 'ready') this.marks = state.playable.fingerMarks

        this.renderer.render(state)
    }

    private listenToTheControls(): void {
        element<HTMLInputElement>('keySlider').addEventListener('input', event => {
            this.viewModel.changeKey(Number((event.target as HTMLInputElement).value))
        })
        element<HTMLSelectElement>('style').addEventListener('change', event => {
            this.viewModel.changeStyle((event.target as HTMLSelectElement).value)
        })
        element<HTMLSelectElement>('notesPerFinger').addEventListener('change', event => {
            this.viewModel.changeNotesPerFinger(Number((event.target as HTMLSelectElement).value))
        })
        element<HTMLSelectElement>('tunes').addEventListener('change', event => {
            const chosen = event.target as HTMLSelectElement
            if (chosen.value !== '') this.viewModel.playTheTune(Number(chosen.value))

            chosen.value = ''
        })
        element('stopTune').addEventListener('click', () => this.viewModel.stopTheTuneAndSilence())
        this.listenToTheFullScreenButton()
        element('startButton').addEventListener('click', () => void this.startSound())
        document.addEventListener('visibilitychange', () => {
            if (document.hidden) this.silence()
        })
        window.addEventListener('pagehide', () => this.silence())
    }

    private listenToTheViewport(): void {
        const relaid = () => this.layOutTheZone()
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

    private async startSound(): Promise<void> {
        const button = element<HTMLButtonElement>('startButton')
        button.disabled = true
        button.textContent = loadingLabel
        await this.viewModel.prepareSound()
        document.body.classList.remove('preparing')
        this.layOutTheZone()
    }

    private silence(): void {
        this.viewModel.stopPlaying()
        this.viewModel.stopShapingTone()
    }

    private playAt(contacts: readonly Contact[]): void {
        const plates = sizeOf(element('plates'))
        this.viewModel.play(contacts, plates)
        this.stripCircles.draw(this.viewModel.marksOnTheStrip(contacts, plates, this.marks))
    }

    private shapeTone(contacts: readonly Contact[]): void {
        const zone = sizeOf(element('zone'))
        this.viewModel.shapeTone(contacts, zone)
        this.zoneCircles.draw(this.viewModel.marksOnTheSquare(contacts, zone))
    }

    private resizeZone(magnification: number): void {
        this.zoneScale = Math.min(largestZoneScale, Math.max(smallestZoneScale, this.zoneScale * magnification))
        this.layOutTheZone()
    }

    private layOutTheZone(): void {
        const viewport = window.visualViewport
        if (viewport !== null) {
            document.documentElement.style.setProperty('--appHeight', `${viewport.height}px`)
        }

        const instrument = element('instrument')
        const natural = Math.min(instrument.clientHeight, instrument.clientWidth * zoneWidthFraction)
        const side = Math.min(instrument.clientHeight, natural * this.zoneScale)
        document.documentElement.style.setProperty('--zoneSide', `${Math.round(side)}px`)
        this.strip.refreshBounds()
        this.zone.refreshBounds()
        this.renderer.fitTheNoteRow()
    }
}

function sizeOf(area: HTMLElement): AreaSize {
    return { width: area.clientWidth, height: area.clientHeight }
}
