import type { Log } from '../../src/logging/log.js'

export class RecordingLog implements Log {
    readonly lines: string[] = []

    record(line: string): void {
        this.lines.push(line)
    }

    recordSample(): void {}
}
