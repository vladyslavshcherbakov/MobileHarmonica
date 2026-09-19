import type { CoreFinger } from '../../core/coreState.js'
import type { FingerMark } from './fingerCircles.js'
import { FingerCircles, restingDiameter } from './fingerCircles.js'
import { HarmonicaRenderer } from './harmonicaRenderer.js'
import type { FingerMarksViewState, HarmonicaViewState } from './harmonicaViewState.js'
import type { HarmonicaViewModel } from './harmonicaViewModel.js'
import type { Contact } from './touchArea.js'
import { TouchArea } from './touchArea.js'

const zoneWidthFraction = 0.22
const smallestZoneScale = 0.45
const largestZoneScale = 2
const holeCount = 10
const loadingLabel = 'loading the reeds'

export class HarmonicaScreen {
    private readonly renderer: HarmonicaRenderer
    private readonly stripCircles: FingerCircles
    private readonly zoneCircles: FingerCircles
    private readonly strip: TouchArea
    private readonly zone: TouchArea
    private marks: FingerMarksViewState = { spansTheMouth: true, onlyTheDecidingFinger: false, holesWide: 2 }
    private zoneScale = 1

    constructor(private readonly viewModel: HarmonicaViewModel) {
        this.renderer = new HarmonicaRenderer({
            body: document.body,
            keyLabel: element('keyLabel'),
            keySlider: element<HTMLInputElement>('keySlider'),
            mouthWidth: element<HTMLSelectElement>('mouthWidth'),
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
            this.viewModel.changeStyle((event.target as HTMLSelectElement).value as never)
        })
        element<HTMLSelectElement>('mouthWidth').addEventListener('change', event => {
            this.viewModel.changeMouthWidth(Number((event.target as HTMLSelectElement).value))
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
        const plates = element('plates')
        const positions = contacts.map(contact => positionOf(contact, plates.clientWidth, plates.clientHeight))
        this.viewModel.playAt(positions)
        this.stripCircles.draw(this.stripMarks(contacts, positions, plates.clientWidth))
    }

    private stripMarks(
        contacts: readonly Contact[],
        positions: readonly CoreFinger[],
        width: number
    ): FingerMark[] {
        const deciding = topmostOf(positions.filter(isOnTheHarmonica))
        const diameter = this.marks.spansTheMouth ? (this.marks.holesWide * width) / holeCount : restingDiameter
        return contacts.flatMap((contact, index) => {
            const position = positions[index]
            if (position === undefined) return []

            const decides = position === deciding
            if (this.marks.onlyTheDecidingFinger ? !decides : !isOnTheHarmonica(position)) return []

            return [{ x: contact.x, y: contact.y, diameter, decidesBreath: decides }]
        })
    }

    private shapeTone(contacts: readonly Contact[]): void {
        const zone = element('zone')
        const leading = topmostContact(contacts)
        if (leading === undefined || contacts.length > 1) {
            this.viewModel.stopShapingTone()
        } else {
            this.viewModel.shapeTone(1 - (2 * leading.y) / zone.clientHeight, leading.x / zone.clientWidth)
        }
        this.zoneCircles.draw(contacts.map(contact => ({
            x: contact.x,
            y: contact.y,
            diameter: restingDiameter,
            decidesBreath: contact === leading
        })))
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

function positionOf(contact: Contact, width: number, height: number): CoreFinger {
    return {
        fractionFromLeftEdge: contact.x / width,
        fractionAboveCentreLine: (height / 2 - contact.y) / height,
        fractionCoveredEitherSide: 0
    }
}

function isOnTheHarmonica(finger: CoreFinger): boolean {
    return finger.fractionFromLeftEdge >= 0 && finger.fractionFromLeftEdge <= 1
}

function topmostOf(fingers: readonly CoreFinger[]): CoreFinger | null {
    let topmost: CoreFinger | null = null
    for (const finger of fingers) {
        if (topmost === null || finger.fractionAboveCentreLine > topmost.fractionAboveCentreLine) {
            topmost = finger
        }
    }
    return topmost
}

function topmostContact(contacts: readonly Contact[]): Contact | undefined {
    let topmost: Contact | undefined
    for (const contact of contacts) {
        if (topmost === undefined || contact.y < topmost.y) topmost = contact
    }
    return topmost
}

function runsAsAnApp(): boolean {
    return (navigator as HomeScreenNavigator).standalone === true
        || window.matchMedia('(display-mode: standalone), (display-mode: fullscreen)').matches
}

interface HomeScreenNavigator extends Navigator {
    standalone?: boolean
}

function theScreenCanBeFilled(): boolean {
    const root = document.documentElement as FullScreenElement
    return root.requestFullscreen !== undefined || root.webkitRequestFullscreen !== undefined
}

async function fillTheScreen(): Promise<void> {
    const shown = shownFullScreen()
    try {
        await (shown === null ? enterFullScreen() : leaveFullScreen())
    } catch (refusal) {
        sayHowElseToFillTheScreen(refusal)
    }
}

function sayHowElseToFillTheScreen(refusal: unknown): void {
    element('fillTheScreenReason').textContent =
        'Safari would not fill the screen from a tab. Open the share menu and add this page to the'
        + ' home screen: started from there it runs without the browser at all.'
    element('fillTheScreenRefusal').textContent = nameOf(refusal)
    document.body.classList.add('askedToFillTheScreen')
}

function nameOf(refusal: unknown): string {
    return refusal instanceof Error ? `${refusal.name}: ${refusal.message}` : String(refusal)
}

function shownFullScreen(): Element | null {
    return document.fullscreenElement ?? (document as FullScreenDocument).webkitFullscreenElement ?? null
}

function enterFullScreen(): Promise<void> | undefined {
    const root = document.documentElement as FullScreenElement
    return root.requestFullscreen?.() ?? root.webkitRequestFullscreen?.()
}

function leaveFullScreen(): Promise<void> | undefined {
    return document.exitFullscreen?.() ?? (document as FullScreenDocument).webkitExitFullscreen?.()
}

interface FullScreenElement extends HTMLElement {
    webkitRequestFullscreen?: () => Promise<void>
}

interface FullScreenDocument extends Document {
    webkitFullscreenElement?: Element | null
    webkitExitFullscreen?: () => Promise<void>
}

function element<T extends HTMLElement = HTMLElement>(id: string): T {
    const found = document.getElementById(id)
    if (found === null) throw new Error(`the page has no element called ${id}`)

    return found as T
}
