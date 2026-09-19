import type { AudioEngine } from '../domain/protocols/audioEngine.js'
import type { Log } from '../domain/protocols/log.js'
import type { Tilt } from '../domain/protocols/tilt.js'
import { tunes } from '../domain/scores/tunes.js'
import { PlayHarmonica } from '../domain/useCases/playHarmonica.js'
import { PlayScore } from '../domain/useCases/playScore.js'
import { HarmonicaPresenter } from '../features/harmonica/harmonicaPresenter.js'
import { HarmonicaViewModel } from '../features/harmonica/harmonicaViewModel.js'
import { HarmonicaScreen } from '../features/harmonica/harmonicaScreen.js'

export class CompositionRoot {
    constructor(
        private readonly audioEngine: AudioEngine,
        private readonly tilt: Tilt,
        private readonly log: Log
    ) {}

    harmonicaScreen(): HarmonicaScreen {
        return new HarmonicaScreen(this.harmonicaViewModel())
    }

    private harmonicaViewModel(): HarmonicaViewModel {
        const playHarmonica = new PlayHarmonica(this.audioEngine, this.log)
        return new HarmonicaViewModel(
            playHarmonica,
            new PlayScore(playHarmonica, this.log),
            this.tilt,
            tunes,
            new HarmonicaPresenter(tunes)
        )
    }
}
