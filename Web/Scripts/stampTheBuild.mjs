import { readFile, rename, rm, writeFile } from 'node:fs/promises'
import { dirname, resolve } from 'node:path'
import { fileURLToPath } from 'node:url'

const version = process.argv[2]
if (version === undefined) throw new Error('the build needs a version to stamp into its paths')

const site = resolve(dirname(fileURLToPath(import.meta.url)), '..')
const stamped = `dist-${version}`

await rm(resolve(site, stamped), { recursive: true, force: true })
await rename(resolve(site, 'dist'), resolve(site, stamped))

const page = resolve(site, 'index.html')
await writeFile(page, (await readFile(page, 'utf8')).replaceAll('dist/src/', `${stamped}/src/`))
console.log(`the page now loads ${stamped}`)
