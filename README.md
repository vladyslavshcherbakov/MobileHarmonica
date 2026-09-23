# MobileHarmonica

An expressive ten-hole diatonic harmonica you play with your fingers. The screen is the
instrument: fingers on the strip sound the holes, their height sets the breath, and a square
beside the strip bends, overblows and adds vibrato. It runs as a native iPhone app and as a web
page built from the same instrument code.

**[Play it in the browser →](https://vladyslavshcherbakov.github.io/MobileHarmonica/)**

## Contents

1. [Projects](#projects)
2. [Platforms](#platforms)
3. [Features](#features)
4. [Getting started](#getting-started)
5. [Testing](#testing)
6. [Repository layout](#repository-layout)
7. [Documentation](#documentation)
8. [Recordings and licence](#recordings-and-licence)

## Projects

| Project | Path | What it is |
|---|---|---|
| **HarmonicaCore** | `Core/` | The instrument itself as a Swift package: tuning, bends and overbends, playing styles, tunes and the score reader. Imports Foundation only, and both platforms run it |
| **MobileHarmonica for iPhone** | `Apps/iOS/` | The native app: SwiftUI screen, a lock-free sampler on a Remote I/O audio unit, and the phone's lean for cupped hands |
| **MobileHarmonica on the web** | `Web/` | The page: TypeScript with no framework or bundler, the sound in an `AudioWorklet`, and HarmonicaCore compiled to WebAssembly |
| **HarmonicaWasm** | `Web/Instrument/` | The Swift package that compiles HarmonicaCore to WebAssembly and exposes it to the page |

The same page also runs as a Telegram mini app, and `Web/src/app/telegram.ts` adapts it to
Telegram's window.

## Platforms

| Platform | Supported | Notes |
|---|---|---|
| iPhone app | iOS 18 or later, landscape | Plays at up to 120 Hz on ProMotion iPhones |
| Safari on iPhone | Current Safari, landscape | Installs to the home screen and runs full screen from there |
| Safari on Mac | Current Safari | Adds a playing style where the trackpad's press sets how many notes sound |
| Other desktop browsers | Current versions | Tested in Chromium. A mouse plays as one finger |
| Telegram mini app | Any client | Full screen and the locked swipe need Bot API 7.7 and 8.0. Not yet run in a client |

## Features

- **Played by touch.** A finger on the strip sounds the hole under it. The topmost finger's
  height is the breath: above the centre line blows, below draws, and the distance from the line
  is how hard.
- **Chords and single notes.** Three playing styles decide how many fingers count and how many
  holes each one covers. On the web a menu sets how many notes one finger takes, and on a Mac the
  trackpad's pressure can set it instead.
- **Bends, overblows and overdraws.** The square beside the strip pulls the sounding reed down
  towards its partner or pops it above, each reed by its own real range, and adds vibrato from
  left to right.
- **Twelve keys.** A slider chooses which harmonica is in your hands, from G to F♯.
- **Cupped hands.** Leaning the phone closes the hands around the harmonica and darkens the tone.
  iPhone only, and it can be turned off in the settings.
- **Settings on the iPhone.** A second screen holds the playing style, cupped hands, and which side
  of the holes the square stands on and how large it is. They are kept between launches.
- **A note row that names what sounds.** Every sounding hole shows its note, and what shifted it
  when a bend or an overbend did: `C♯5` over `(D5 bend)`.
- **Recorded sound.** Every note is a recorded harmonica, read at the pitch asked for, with the
  attack, the crossfade and the ring down a reed has.
- **Seven built-in tunes** played through the instrument itself, from a twelve-bar blues to three
  Ukrainian folk melodies, with slides, shakes and scoops. On the phone a score written as text
  joins them.
- **Low latency.** The phone asks for the shortest audio buffer the hardware allows and renders
  with no lock and no allocation on the audio thread. The page renders in an `AudioWorklet` that
  owns its voices.

## Getting started

### Requirements

| To build | You need |
|---|---|
| The iPhone app | macOS with Xcode carrying the iOS 18 SDK or later, and [Tuist](https://docs.tuist.dev/en/guides/install-tuist) 4 |
| HarmonicaCore's tests | Swift 6 on a Mac, with no simulator |
| The page | Node.js 22, and the Swift 6.4 toolchain with the `swift-6.4.0-RELEASE_wasm` SDK for the WebAssembly core |

### The iPhone app

```sh
./build.sh                    # generates MobileHarmonica.xcworkspace from Project.swift
open MobileHarmonica.xcworkspace
```

Run the `MobileHarmonica` scheme on an iPhone or a simulator. Rerun `./build.sh` after cloning,
after adding or removing a file, and after any change to `Project.swift`. The Xcode project, the
workspace and `Derived/` are generated and not committed. Audio latency can only be judged on a device: the log names the buffer the
phone granted and the latency to the speaker.

### The page

```sh
cd Web
npm install                   # TypeScript, the page's only dependency
./build.sh                    # the WebAssembly core, then the page and its tests
npx http-server -p 8123 .     # then open http://<this machine>:8123 in landscape
```

`./build.sh core` and `./build.sh page` build either half alone. What each step does is in
[Web/AGENTS.md](Web/AGENTS.md).

### Deployment

`.github/workflows/pages.yml` builds the WebAssembly core and runs the page's tests on every push,
to any branch, that touches `Core/` or `Web/`. Pushes to `master` also publish `Web/` to GitHub
Pages.

## Testing

| Suite | Runs with | What it holds |
|---|---|---|
| HarmonicaCore | `swift test` inside `Core/`, or the app's scheme | What the instrument promises: tuning, playing styles, what a mouth covers, scores |
| The app | The `MobileHarmonica` scheme in Xcode | The screen driven through the app's own graph, the sampler rendered offline, and a performance budget |
| The page | `./build.sh page` inside `Web/`, and CI | The presenter, the touch mappers, the sampler, and the page's graph over the real WebAssembly core |

The package's tests are compiled into the app's test bundle as well, so they also run on a
device, where Xcode cannot host a package's own test target.

## Repository layout

```
Core/                   HarmonicaCore: Entities, Protocols and UseCases, plus its tests
Apps/iOS/
  App/                  entry point and composition root
  Audio/                the sampler and the Remote I/O output
  Motion/               the phone's lean, through Core Motion
  Features/Harmonica/   the screen, its view model, presenter, view state, Views/ and Touch/
  Features/Settings/    the settings screen, its view model, presenter and view state
  Settings/             the player's settings and the repository that keeps them in UserDefaults
  Logging/              the timestamped log
  Navigation/           coordinator and routes
  Scores/               text scores read at launch, not committed
  Tests/                the app's tests and their support
Web/
  src/                  the page: core/, audio/, features/, logging/, app/
  tests/                the page's tests
  Instrument/           HarmonicaWasm, the WebAssembly package
  Scripts/              the build steps build.sh runs
Resources/Samples/      the recordings both platforms play
docs/                   how the instrument behaves, with ios/ and web/ per platform
build.sh                generates the Xcode project with Tuist
Project.swift           targets, platform, build settings and Info.plist
Tuist.swift             Tuist's own configuration
```

## Documentation

| Document | For |
|---|---|
| [docs/instrument.md](docs/instrument.md) | The harmonica: tuning, bends, overbends, keys and positions |
| [docs/playing.md](docs/playing.md) | How it is played on every platform: the strip, the square, breath, playing styles and tunes |
| [docs/sound.md](docs/sound.md) | How the sound is made on every platform: voices, crossfades, recordings, mix, bend, cup and vibrato |
| [docs/ios/](docs/ios/) | What the iPhone adds: a finger's width, the lean, the screen, written scores, the Remote I/O output |
| [docs/web/](docs/web/) | What the page does differently: the notes control, the trackpad's press, loading the recordings, Safari and Telegram |
| [AGENTS.md](AGENTS.md) | How to work on the code: workflow, architecture, where things live, conventions, tests |
| [Web/AGENTS.md](Web/AGENTS.md) | How to work on the page's code: its build and publishing, architecture and tests |
| [Apps/iOS/Scores/README.md](Apps/iOS/Scores/README.md) | The text format of a score |
| [Resources/Samples/README.md](Resources/Samples/README.md) | Where the recordings come from and how they are named |

## Recordings and licence

The recordings are a commercial harmonica library, committed in `Resources/Samples/` and served
by the published page. Their licence has not been read, so whether they may be redistributed is
unsettled. Replace them with recordings you hold the rights to before shipping the app.
