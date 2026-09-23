declare module 'node:test' {
    export function test(name: string, run: () => void | Promise<void>): void
    export function test(name: string, options: { skip?: string | false }, run: () => void | Promise<void>): void
}

declare module 'node:assert/strict' {
    interface Assert {
        equal(actual: unknown, expected: unknown, message?: string): void
        notEqual(actual: unknown, expected: unknown, message?: string): void
        deepEqual(actual: unknown, expected: unknown, message?: string): void
        ok(value: unknown, message?: string): void
        throws(run: () => unknown, expected?: RegExp, message?: string): void
    }

    const assert: Assert
    export default assert
}

declare const process: { readonly env: Record<string, string | undefined> }

declare module 'node:fs' {
    export function readFileSync(path: URL, encoding: 'utf8'): string
    export function readFileSync(path: URL): Uint8Array<ArrayBuffer>
    export function readdirSync(path: URL): string[]
    export function existsSync(path: URL): boolean
}

declare module 'node:v8' {
    export function setFlagsFromString(flags: string): void
}

declare module 'node:vm' {
    export function runInNewContext(code: string): unknown
}
