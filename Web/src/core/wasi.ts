const errorSuccess = 0
const errorNotSupported = 58
const nanosecondsPerMillisecond = 1_000_000

export interface WasiHost {
    readonly imports: Record<string, WebAssembly.ImportValue>
    useMemory(memory: WebAssembly.Memory): void
}

export function wasiHost(write: (line: string) => void): WasiHost {
    let memory: WebAssembly.Memory | null = null
    const pending = new Map<number, string>()

    const view = (): DataView => new DataView((memory as WebAssembly.Memory).buffer)
    const bytes = (): Uint8Array<ArrayBuffer> =>
        new Uint8Array((memory as WebAssembly.Memory).buffer as ArrayBuffer)

    const writeTo = (file: number, vectors: number, count: number, written: number): number => {
        let total = 0
        let text = pending.get(file) ?? ''
        for (let vector = 0; vector < count; vector += 1) {
            const at = vectors + vector * 8
            const start = view().getUint32(at, true)
            const length = view().getUint32(at + 4, true)
            text += new TextDecoder().decode(bytes().subarray(start, start + length))
            total += length
        }
        view().setUint32(written, total, true)
        const lines = text.split('\n')
        pending.set(file, lines.pop() ?? '')
        for (const line of lines) write(line)

        return errorSuccess
    }

    return {
        useMemory(given: WebAssembly.Memory): void {
            memory = given
        },
        imports: {
            fd_write: (file: number, vectors: number, count: number, written: number) =>
                writeTo(file, vectors, count, written),
            fd_close: () => errorSuccess,
            fd_fdstat_get: () => errorSuccess,
            fd_seek: () => errorNotSupported,
            fd_read: () => errorNotSupported,
            fd_prestat_get: () => errorNotSupported,
            fd_prestat_dir_name: () => errorNotSupported,
            path_open: () => errorNotSupported,
            environ_sizes_get: (count: number, size: number) => {
                view().setUint32(count, 0, true)
                view().setUint32(size, 0, true)
                return errorSuccess
            },
            environ_get: () => errorSuccess,
            args_sizes_get: (count: number, size: number) => {
                view().setUint32(count, 0, true)
                view().setUint32(size, 0, true)
                return errorSuccess
            },
            args_get: () => errorSuccess,
            clock_time_get: (_clock: number, _precision: bigint, time: number) => {
                view().setBigUint64(time, BigInt(Math.round(Date.now() * nanosecondsPerMillisecond)), true)
                return errorSuccess
            },
            clock_res_get: (_clock: number, resolution: number) => {
                view().setBigUint64(resolution, BigInt(nanosecondsPerMillisecond), true)
                return errorSuccess
            },
            random_get: (at: number, length: number) => {
                crypto.getRandomValues(bytes().subarray(at, at + length))
                return errorSuccess
            },
            poll_oneoff: () => errorNotSupported,
            sched_yield: () => errorSuccess,
            proc_exit: (code: number) => {
                throw new Error(`the instrument stopped itself with ${code}`)
            }
        }
    }
}
