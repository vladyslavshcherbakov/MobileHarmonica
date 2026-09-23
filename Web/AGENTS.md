# MobileHarmonica on the web — working on the code

How to work on the page: its build and publishing, its architecture, where its files live and how
it is tested. The repository's workflow and conventions in [AGENTS.md](../AGENTS.md) hold here
too. How the page behaves is in [docs/web/](../docs/web/).

## Workflow

**`build.sh` is the whole pipeline**, and every step it calls is in `Scripts/`. The commands are in
the [README](../README.md#the-page). CI runs the same script, so CI and a laptop build the page
the same way.

| Part | What runs |
|---|---|
| `./build.sh core` | Builds `Instrument/` for WebAssembly into `core/harmonica.wasm` |
| `./build.sh page [commit]` | Copies the recordings into `samples/`, compiles to `dist/`, runs the tests, and with a commit stamps the publish |
| `./build.sh` | Both, core first |

**Every publish lives at its own address.** With a commit, `dist` becomes `dist-<commit>` and the
page's one script tag points at it, so a browser cache never mixes two builds. Every path in the
page is relative.

**Serving locally** is any static server over `Web/`. A `file:` URL does not work, because the page
fetches the core and the recordings.

## Architecture

The page is TypeScript compiled to ES modules, with no framework and no bundler. The instrument is
`Core/` compiled to WebAssembly, and the page adds only the sound, the screen, the fingers and the
clock.

**The core's boundary is narrow.** `Instrument/` declares the module's exports and its two
imports, the audio engine and the log. Fingers go in as one buffer of doubles, and the harmonica
comes out as JSON read into the types in `src/core/`. Each export enters the main actor, since
WebAssembly has one thread.

**Only values cross it.** The core refuses a hole that is not exactly a hole number, because one
`NaN` turned into an integer traps the module for good. Every optional is encoded as an explicit
`null`, never left out.

**WASI is shimmed.** `src/core/wasi.ts` names all of preview1's calls and answers the few Foundation
uses. A call the shim lacks is a `LinkError` that kills the module, so a test compares the names
with the specification.

**The clock is on the page.** The tune player walks a tune's events and drives the instrument
through the same calls a finger does, because the core has no executor to sleep on.

**The sampler is one audio worklet file with no imports**, because Safari's `addModule` cannot be
trusted with them. The audio thread owns every voice and the main thread only posts messages.
GitHub Pages cannot send the headers `SharedArrayBuffer` needs, so there is no shared memory.

**Force Touch** is read only from `webkitmouseforcechanged`, on the window. The force a pointer
event carries does not follow the press.

## Where things live

```
Web/
  index.html, styles.css, manifest.webmanifest
  src/
    core/               the WASI shim, the loader, the module wrapper, the DTOs
    audio/              the worklet, the engine that talks to it, reading the recordings
    features/harmonica/ screen, view state, presenter, view model, renderer, tune player,
                        with touch/ and page/
    logging/            the timestamped log
    app/                composition root, entry point, Telegram adapter
  tests/                one file per promise, support/ for the environment and doubles
  Instrument/           the Swift package that compiles Core/ to WebAssembly
  Scripts/              the steps build.sh runs
```

`dist/`, `dist-*/`, `core/`, `samples/` and `node_modules/` are generated and not committed.

## Tests

- Files end in `.unit.test.ts` or `.integration.test.ts`. Names follow `subject_whenCondition_outcome`.
- Integration tests run the page's own graph over the real WebAssembly module. Without `core/harmonica.wasm` they are skipped locally and fail in CI.
- The page tests only what it adds to the core: presenter, touch mappers, sampler, recordings, the shim.
- A test reads the audio code of both platforms and fails if a shared constant has drifted.
- A release test turns on `gc` through `node:v8`, so it needs no flag.
