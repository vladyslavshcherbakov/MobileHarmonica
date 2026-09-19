import { SampledAudioEngine } from '../audio/sampledAudioEngine.js'
import { DeviceTilt } from '../motion/deviceTilt.js'
import { TimestampedLog } from '../logging/timestampedLog.js'
import { CompositionRoot } from './compositionRoot.js'

const log = new TimestampedLog()
const samplesFolder = 'samples'
const workletUrl = new URL('../audio/harmonicaWorklet.js', import.meta.url).href
const compositionRoot = new CompositionRoot(
    new SampledAudioEngine(workletUrl, samplesFolder, log),
    new DeviceTilt(),
    log
)

document.body.classList.add('preparing')
compositionRoot.harmonicaScreen().start()
