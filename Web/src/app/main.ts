import { SampledAudioEngine } from '../audio/sampledAudioEngine.js'
import { DeviceTilt } from '../motion/deviceTilt.js'
import { TimestampedLog } from '../logging/timestampedLog.js'
import { CompositionRoot } from './compositionRoot.js'

const log = new TimestampedLog()
const samplesFolder = 'samples'
const workletUrl = new URL('../audio/harmonicaWorklet.js', import.meta.url).href
const coreUrl = new URL('../../../core/harmonica.wasm', import.meta.url).href
const compositionRoot = new CompositionRoot(
    coreUrl,
    new SampledAudioEngine(workletUrl, samplesFolder, log),
    new DeviceTilt(),
    log
)

document.body.classList.add('preparing')
const startButton = document.getElementById('startButton') as HTMLButtonElement
const startLabel = startButton.textContent
startButton.disabled = true
startButton.textContent = 'loading the instrument'
const screen = await compositionRoot.harmonicaScreen()
startButton.disabled = false
startButton.textContent = startLabel
screen.start()
