import type { AudioEngine } from '../core/audioEngine.js'
import { HarmonicaCore } from '../core/harmonicaCore.js'
import type { Log } from '../logging/log.js'
import { HarmonicaPresenter } from '../features/harmonica/harmonicaPresenter.js'
import { HarmonicaViewModel } from '../features/harmonica/harmonicaViewModel.js'
import { HarmonicaScreen } from '../features/harmonica/harmonicaScreen.js'
import { PlayTheTuneUseCase } from '../features/harmonica/playTheTuneUseCase.js'

export class CompositionRoot {
    constructor(
        private readonly coreUrl: string,
        private readonly audioEngine: AudioEngine,
        private readonly log: Log,
        private readonly forceTouchCanBeRead: boolean
    ) {}

    async harmonicaScreen(): Promise<HarmonicaScreen> {
        const core = await HarmonicaCore.load(this.coreUrl, this.audioEngine, this.log)
        return new HarmonicaScreen(this.harmonicaViewModel(core))
    }

    harmonicaViewModel(core: HarmonicaCore): HarmonicaViewModel {
        const tunes = core.tunes()
        return new HarmonicaViewModel(
            core,
            this.audioEngine,
            new PlayTheTuneUseCase(core, tunes, core.reeds(), core.timing()),
            new HarmonicaPresenter(tunes, this.forceTouchCanBeRead),
            this.log
        )
    }
}
