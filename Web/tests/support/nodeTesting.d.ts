declare module 'node:test' {
    export function test(name: string, run: () => void | Promise<void>): void
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
