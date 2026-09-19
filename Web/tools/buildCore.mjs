import { cp, mkdir, stat } from 'node:fs/promises'
import { spawnSync } from 'node:child_process'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const core = resolve(here, '../../Core')
const served = resolve(here, '../core')
const sdk = process.env.SWIFT_WASM_SDK ?? 'wasm32-unknown-wasi'

const built = spawnSync(
    'swift',
    ['build', '--package-path', core, '--product', 'HarmonicaWasm', '--swift-sdk', sdk, '-c', 'release'],
    { stdio: 'inherit' }
)
if (built.status !== 0) {
    throw new Error(`swift build failed with ${built.status}; is the WebAssembly SDK installed?`)
}

const wasm = resolve(core, '.build/release/HarmonicaWasm.wasm')
await stat(wasm)
await mkdir(served, { recursive: true })
await cp(wasm, resolve(served, 'harmonica.wasm'))
console.log('the instrument is ready to serve')
