import { element } from './pageElement.js'

export function runsAsAnApp(): boolean {
    return (navigator as HomeScreenNavigator).standalone === true
        || window.matchMedia('(display-mode: standalone), (display-mode: fullscreen)').matches
}

interface HomeScreenNavigator extends Navigator {
    standalone?: boolean
}

export function theScreenCanBeFilled(): boolean {
    const root = document.documentElement as FullScreenElement
    return root.requestFullscreen !== undefined || root.webkitRequestFullscreen !== undefined
}

export async function fillTheScreen(): Promise<void> {
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
