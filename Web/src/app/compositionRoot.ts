import type { CoreAudio } from '../core/coreState.js'
import { HarmonicaCore } from '../core/harmonicaCore.js'
import type { Log } from '../logging/log.js'
import { HarmonicaPresenter } from '../features/harmonica/harmonicaPresenter.js'
import { HarmonicaViewModel } from '../features/harmonica/harmonicaViewModel.js'
import { HarmonicaScreen } from '../features/harmonica/harmonicaScreen.js'
import { PlayTheTune } from '../features/harmonica/playTheTune.js'

export class CompositionRoot {
    constructor(
        private readonly coreUrl: string,
        private readonly audioEngine: CoreAudio & { prepare(): Promise<void> },
        private readonly log: Log
    ) {}

    async harmonicaScreen(): Promise<HarmonicaScreen> {
        const core = await HarmonicaCore.load(this.coreUrl, this.audioEngine, line => this.log.record(line))
        return new HarmonicaScreen(this.harmonicaViewModel(core))
    }

    private harmonicaViewModel(core: HarmonicaCore): HarmonicaViewModel {
        const tunes = core.tunes()
        return new HarmonicaViewModel(
            core,
            this.audioEngine,
            new PlayTheTune(core, tunes, core.reeds(), core.timing()),
            new HarmonicaPresenter(tunes),
            this.log
        )
    }
}
