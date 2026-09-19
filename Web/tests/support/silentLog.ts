import type { Log } from '../../src/domain/protocols/log.js'

export class SilentLog implements Log {
    record(): void {}

    recordSample(): void {}
}
