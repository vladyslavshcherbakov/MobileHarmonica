import type { Log } from '../logging/log.js'

const scriptUrl = 'https://telegram.org/js/telegram-web-app.js'
const launchMark = 'tgWebAppPlatform'
const windowEvents = ['safeAreaChanged', 'contentSafeAreaChanged', 'fullscreenChanged', 'viewportChanged']

export interface TelegramInset {
    readonly top?: number
    readonly left?: number
}

export interface TelegramWindow {
    ready(): void
    expand(): void
    disableVerticalSwipes?: () => void
    requestFullscreen?: () => void
    unlockOrientation?: () => void
    onEvent?: (event: string, happened: () => void) => void
    readonly version?: string
    readonly platform?: string
    readonly safeAreaInset?: TelegramInset
    readonly contentSafeAreaInset?: TelegramInset
}

type WindowRequest = 'disableVerticalSwipes' | 'requestFullscreen' | 'unlockOrientation'

export function launchedFromTelegram(hash: string): boolean {
    return hash.includes(launchMark)
}

export function fitTheWindow(telegram: TelegramWindow, log: Log): void {
    telegram.ready()
    telegram.expand()
    ask(telegram, 'disableVerticalSwipes', log)
    ask(telegram, 'requestFullscreen', log)
    ask(telegram, 'unlockOrientation', log)
}

export async function fitIntoTelegram(log: Log): Promise<void> {
    if (!launchedFromTelegram(window.location.hash)) return

    const telegram = await telegramWindow(log)
    if (telegram === null) return

    log.record(`inside Telegram ${telegram.platform ?? 'somewhere'}, version ${telegram.version ?? 'unknown'}`)
    document.body.classList.add('insideTelegram')
    fitTheWindow(telegram, log)
    followTheInsets(telegram)
}

function ask(telegram: TelegramWindow, request: WindowRequest, log: Log): void {
    const call = telegram[request]
    if (call === undefined) return log.record(`this Telegram is too old for ${request}`)

    call.call(telegram)
    log.record(`telegram asked for ${request}`)
}

async function telegramWindow(log: Log): Promise<TelegramWindow | null> {
    log.record(`launched from Telegram, reading ${scriptUrl}`)
    const loaded = await loadTheScript()
    if (!loaded) {
        log.record('the Telegram script did not load, the page stays a page')
        return null
    }

    const telegram = (window as TelegramHost).Telegram?.WebApp ?? null
    if (telegram === null) log.record('the Telegram script loaded but left no window behind')

    return telegram
}

function loadTheScript(): Promise<boolean> {
    return new Promise(settled => {
        const script = document.createElement('script')
        script.src = scriptUrl
        script.addEventListener('load', () => settled(true))
        script.addEventListener('error', () => settled(false))
        document.head.append(script)
    })
}

function followTheInsets(telegram: TelegramWindow): void {
    const apply = () => {
        showTheInsets(telegram)
        window.dispatchEvent(new Event('resize'))
    }
    apply()
    for (const event of windowEvents) telegram.onEvent?.(event, apply)
}

function showTheInsets(telegram: TelegramWindow): void {
    const style = document.documentElement.style
    style.setProperty('--telegramTopInset', `${furthest(telegram, 'top')}px`)
    style.setProperty('--telegramLeftInset', `${furthest(telegram, 'left')}px`)
}

function furthest(telegram: TelegramWindow, edge: 'top' | 'left'): number {
    return Math.max(telegram.safeAreaInset?.[edge] ?? 0, telegram.contentSafeAreaInset?.[edge] ?? 0)
}

interface TelegramHost extends Window {
    Telegram?: { WebApp?: TelegramWindow }
}
