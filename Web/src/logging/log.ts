export interface Log {
    record(line: string): void
    recordSample(line: string): void
}
