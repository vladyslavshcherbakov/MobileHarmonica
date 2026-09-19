import { cp, mkdir, readdir, writeFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const shared = resolve(here, '../../Resources/Samples')
const served = resolve(here, '../samples')

const names = (await readdir(shared)).filter(name => name.endsWith('.wav')).sort()
await mkdir(served, { recursive: true })
for (const name of names) {
    await cp(resolve(shared, name), resolve(served, name))
}
await writeFile(resolve(served, 'index.json'), `${JSON.stringify({ samples: names }, null, 2)}\n`)
console.log(`${names.length} recordings ready to serve`)
