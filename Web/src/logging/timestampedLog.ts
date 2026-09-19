import type { Log } from '../domain/protocols/log.js'

export class TimestampedLog implements Log {
    record(line: string): void {
        console.info(stamped(line))
    }

    recordSample(line: string): void {
        console.debug(stamped(line))
    }
}

function stamped(line: string): string {
    return `${new Date().toISOString().replace('T', ' ').replace('Z', '')} ${line}`
}
