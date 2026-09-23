import { test } from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync, readdirSync } from 'node:fs'

const swiftEngine = new URL('../../../Apps/iOS/Audio/', import.meta.url)
const webEngine = new URL('../../src/audio/', import.meta.url)
const swiftConstant = /let ([A-Za-z]+) = (-?[0-9.]+)$/
const webConstant = /^const ([A-Za-z]+) = (-?[0-9.]+)$/

test('engines_whereBothNameTheSameNumber_holdTheSameValue', () => {
    const swift = numbersIn(swiftEngine, '.swift', swiftConstant)
    const web = numbersIn(webEngine, '.ts', webConstant)
    const shared = [...swift.keys()].filter(name => web.has(name))

    assert.ok(shared.length > 15, `only ${shared.length} constants were read, so the reading is broken`)
    for (const name of shared) {
        assert.equal(web.get(name), swift.get(name), `${name} means one thing on the phone and another here`)
    }
})

function numbersIn(folder: URL, extension: string, named: RegExp): Map<string, number> {
    const found = new Map<string, number>()
    for (const file of readdirSync(folder).filter(name => name.endsWith(extension))) {
        for (const line of readFileSync(new URL(file, folder), 'utf8').split('\n')) {
            const constant = named.exec(line.trim())
            if (constant === null) continue

            const name = constant[1] as string
            if (!found.has(name)) found.set(name, Number(constant[2]))
        }
    }
    return found
}
