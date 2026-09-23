import { test } from 'node:test'
import assert from 'node:assert/strict'
import { wasiHost } from '../src/core/wasi.js'

const everyCallInPreviewOne = [
    'args_get', 'args_sizes_get', 'clock_res_get', 'clock_time_get', 'environ_get',
    'environ_sizes_get', 'fd_advise', 'fd_allocate', 'fd_close', 'fd_datasync', 'fd_fdstat_get',
    'fd_fdstat_set_flags', 'fd_fdstat_set_rights', 'fd_filestat_get', 'fd_filestat_set_size',
    'fd_filestat_set_times', 'fd_pread', 'fd_prestat_dir_name', 'fd_prestat_get', 'fd_pwrite',
    'fd_read', 'fd_readdir', 'fd_renumber', 'fd_seek', 'fd_sync', 'fd_tell', 'fd_write',
    'path_create_directory', 'path_filestat_get', 'path_filestat_set_times', 'path_link',
    'path_open', 'path_readlink', 'path_remove_directory', 'path_rename', 'path_symlink',
    'path_unlink_file', 'poll_oneoff', 'proc_exit', 'proc_raise', 'random_get', 'sched_yield',
    'sock_accept', 'sock_recv', 'sock_send', 'sock_shutdown'
]

test('wasi_whateverTheModuleImports_isCallable', () => {
    const host = wasiHost(() => {})

    for (const call of everyCallInPreviewOne) {
        assert.equal(typeof host.imports[call], 'function', `the module may import ${call}`)
    }
})

test('wasi_whenTheModuleWritesALine_itReachesTheLog', () => {
    const lines: string[] = []
    const host = wasiHost(line => lines.push(line))
    const memory = new WebAssembly.Memory({ initial: 1 })
    host.useMemory(memory)
    const written = new TextEncoder().encode('speaking\n')
    new Uint8Array(memory.buffer).set(written, 64)
    const view = new DataView(memory.buffer)
    view.setUint32(0, 64, true)
    view.setUint32(4, written.length, true)

    const answer = (host.imports.fd_write as (...given: number[]) => number)(1, 0, 1, 32)

    assert.equal(answer, 0)
    assert.deepEqual(lines, ['speaking'])
    assert.equal(view.getUint32(32, true), written.length)
})
