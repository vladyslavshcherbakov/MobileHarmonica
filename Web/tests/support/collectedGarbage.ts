import { setFlagsFromString } from 'node:v8'
import { runInNewContext } from 'node:vm'
import { waitUntil } from './waitUntil.js'

setFlagsFromString('--expose-gc')
const collectGarbage = runInNewContext('gc') as () => void

export function isCollected(weakReference: WeakRef<object>): Promise<boolean> {
    return waitUntil(() => {
        collectGarbage()
        return weakReference.deref() === undefined
    })
}
