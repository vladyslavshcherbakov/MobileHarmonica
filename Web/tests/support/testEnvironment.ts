import { existsSync, readFileSync } from 'node:fs'
import { CompositionRoot } from '../../src/app/compositionRoot.js'
import { HarmonicaCore } from '../../src/core/harmonicaCore.js'
import { HarmonicaScreenDriver } from './harmonicaScreenDriver.js'
import { RecordingAudio } from './recordingAudio.js'
import { RecordingLog } from './recordingLog.js'

const builtCore = new URL('../../../core/harmonica.wasm', import.meta.url)

export const withoutTheBuiltCore: string | false = existsSync(builtCore) || process.env.CI === 'true'
    ? false
    : 'core/harmonica.wasm is not built here; the Pages workflow builds it before these run'

export class TestEnvironment {
    readonly audio = new RecordingAudio()
    readonly log = new RecordingLog()

    async core(): Promise<HarmonicaCore> {
        const compiled = await WebAssembly.compile(readFileSync(builtCore))
        return HarmonicaCore.started(compiled, this.audio, this.log)
    }

    async harmonicaScreen(): Promise<HarmonicaScreenDriver> {
        const core = await this.core()
        const screen = new HarmonicaScreenDriver(new CompositionRoot('', this.audio, this.log, false).harmonicaViewModel(core))
        await screen.viewModel.prepareSound()
        return screen
    }
}
