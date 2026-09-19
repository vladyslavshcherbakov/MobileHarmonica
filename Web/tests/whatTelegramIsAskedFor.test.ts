import { test } from 'node:test'
import assert from 'node:assert/strict'
import type { Log } from '../src/logging/log.js'
import type { TelegramWindow } from '../src/app/telegram.js'
import { fitTheWindow, launchedFromTelegram } from '../src/app/telegram.js'

test('launch_whenTheAddressCarriesTelegramsOwnMark_isReadAsTelegram', () => {
    assert.equal(launchedFromTelegram('#tgWebAppData=x&tgWebAppVersion=8.0&tgWebAppPlatform=ios'), true)
    assert.equal(launchedFromTelegram(''), false)
    assert.equal(launchedFromTelegram('#dist-a238a3d'), false)
})

test('window_whenTelegramIsRecent_asksForEverythingTheInstrumentNeeds', () => {
    const asked: string[] = []
    const telegram = recent(asked)

    fitTheWindow(telegram, silentLog())

    assert.deepEqual(asked, [
        'ready',
        'expand',
        'disableVerticalSwipes',
        'requestFullscreen',
        'lockOrientation'
    ])
})

test('window_whenTelegramIsTooOld_saysSoAndCarriesOn', () => {
    const asked: string[] = []
    const lines: string[] = []
    const telegram: TelegramWindow = {
        ready: () => asked.push('ready'),
        expand: () => asked.push('expand')
    }

    fitTheWindow(telegram, { record: line => lines.push(line), recordSample: () => {} })

    assert.deepEqual(asked, ['ready', 'expand'], 'nothing it cannot do is called')
    assert.deepEqual(lines, [
        'this Telegram is too old for disableVerticalSwipes',
        'this Telegram is too old for requestFullscreen',
        'this Telegram is too old for lockOrientation'
    ])
})

function recent(asked: string[]): TelegramWindow {
    return {
        ready: () => asked.push('ready'),
        expand: () => asked.push('expand'),
        disableVerticalSwipes: () => asked.push('disableVerticalSwipes'),
        requestFullscreen: () => asked.push('requestFullscreen'),
        lockOrientation: () => asked.push('lockOrientation')
    }
}

function silentLog(): Log {
    return { record: () => {}, recordSample: () => {} }
}
