# MobileHarmonica — working on the code

How to work on this repository: the workflow, the architecture and the implementation details
that matter, where files live, and the conventions. What the product is and how to build it is in
[README.md](README.md). How it behaves is in [docs/](docs/). The page has its own companion,
[Web/AGENTS.md](Web/AGENTS.md).

## Workflow

**Branches.** `master` is the only long-lived branch and the default. Work happens on a branch off
it. An agent may commit and push its branch without asking. `master` changes when the user says so.

**Before changing behaviour,** read the part of [docs/](docs/) it touches. A change that
contradicts it is a change to the product and is agreed first.

**Before committing,** run what covers the change. Commands are in the README.

| Changed | Run |
|---|---|
| `Core/` | `swift test` inside `Core/`, and the page's tests, which run the core as WebAssembly |
| `Apps/iOS/` | The `MobileHarmonica` scheme's tests in Xcode, which include the core's |
| `Web/` | `./build.sh page` inside `Web/` |
| `Project.swift` | `./build.sh`, then a build in Xcode |

**CI** is the Pages workflow. Every branch compiles `Core/` to WebAssembly and runs the page's
tests. Only `master` publishes the page. No XCTest suite runs in CI, so the app is built in Xcode.

**Documents.** A change updates the one document that owns what it changed. Commands,
requirements, platforms and features are in the README. Behaviour shared by both platforms is in
`docs/`, and one platform's in `docs/ios/` or `docs/web/`. How the code is built and written is
here or in Web/AGENTS.md. None of them records history, git does.

**Constraints.** Swift 6 language mode everywhere, so a data race is a compile error. The app
targets iOS 18, which `Synchronization` needs. No dependencies beyond ComposableArchitecture and no tools beyond
Tuist and the build scripts without asking. Everything committed is in English.

## Architecture

The instrument is a Swift package that both platforms run. Each platform adds only the sound,
the screen and the input.

| Layer | Path | May import | Owns |
|---|---|---|---|
| Domain | `Core/` | Foundation | Entities, ports, use cases |
| Audio | `Apps/iOS/Audio/` | AVFoundation, AudioToolbox, Synchronization | The sampler and the output behind `AudioEngineProtocol` |
| Motion | `Apps/iOS/Motion/` | CoreMotion, UIKit | The lean behind `TiltProtocol` |
| Presentation | `Apps/iOS/Features/` | SwiftUI, UIKit, Combine | View states, presenters, view models, views |
| Composition | `Apps/iOS/App/` | everything | Building the graph |
| Page | `Web/` | the browser | The page around the core compiled to WebAssembly |

**The domain is a package**, so the compiler holds the boundary. The app reaches only its public
API and the package cannot see the app. Only values cross a boundary, and the log arrives
through `LogProtocol`.

**One graph.** `InstrumentGraph` builds the use cases for the app, the WebAssembly module and the
package's tests. `CompositionRoot` takes everything that leaves the process as a parameter, so a
test runs the app's own graph with doubles at the edges.

**One use case plays the instrument.** `PlayHarmonicaUseCase` covers playing, changing key and
shaping the tone, because all three change the reeds sounding now. Every action returns the whole
`Harmonica`, and what the player hears is derived from it, never stored beside it.

**Screens are ComposableArchitecture reducers, the instrument is not.** `AppFeature` owns
navigation, `HarmonicaFeature` the sound's preparation, the settings the harmonica screen follows
and the lean, `SettingsFeature` the settings. Touches, the square, the key slider and tunes go
straight to `HarmonicaViewModel` on the main actor, because an effect would put a task between a
touch and its sound and could reorder two of them. The reducers reach the instrument, the lean and
the stored settings through the clients in `Dependencies/`.

**Presentation.** A presenter turns domain values into a view state that names no domain type.
Views hand raw touches to the view model, and touch mappers turn them into positions and shaping,
so no view imports the domain.

**Errors are mapped at the boundary.** `prepare()` throws a typed `AudioEngineError`, and the
audio layer logs the platform error it maps.

## Concurrency and latency

**The instrument runs on the main actor.** The use cases, the ports and everything implementing
them are `@MainActor`, because every input arrives there: a touch, a lean and each step of a tune.
There is no custom actor, since it would put a hop in front of every touch and could reorder two
of them. Initialisers are `nonisolated`, so the WebAssembly module can build the graph and enter
the main actor in each export.

**The render thread owns the voices, lock-free.** The output is a Core Audio Remote I/O unit with
a C render callback, so no closure, actor or lock sits between the hardware and the voices. The
main thread pushes commands into a single-writer single-reader queue with `Atomic` indices and
slots allocated once. The render thread drains it at the start of every buffer into a bank of at
most 32 voices. Breath, bend, vibrato and the cup are an `Atomic` each. A buffer takes no lock and
allocates nothing.

**The shortest buffer the phone allows.** The session asks for 1 ms in `.measurement` mode and
logs what it got. It is configured and the recordings are read in detached tasks, because
`AVAudioSession` can block.

**120 Hz.** `CADisableMinimumFrameDurationOnPhone` lets a ProMotion screen deliver touches every
8.3 ms instead of 16.7.

## Where things live

```
Core/
  Sources/HarmonicaCore/              Entities/, Protocols/, UseCases/, InstrumentGraph
  Sources/HarmonicaCoreTestSupport/   doubles and helpers the tests share
  Tests/HarmonicaCoreTests/           what the instrument promises
Apps/iOS/
  App/                  the app, CompositionRoot, the score repository
  Audio/                ReedSampler and SampledAudioEngine
  Motion/               DeviceTilt
  Features/Harmonica/   screen, view model, presenter, view state, with Views/ and Touch/
  Features/Settings/    the settings screen, view model, presenter, view state
  Settings/             PlayerSettings and SettingsRepository over UserDefaults
  Navigation/           AppFeature and AppScreen, the navigation stack
  Dependencies/         the clients the reducers reach the instrument, the lean and the settings through
  Scores/               .score files read at launch, not committed
  Tests/                the app's tests and their support
Web/                    the page, see Web/AGENTS.md
Resources/Samples/      the recordings, shared by both platforms
docs/                   how the product behaves
Project.swift           targets, settings, Info.plist
Tuist.swift             Tuist's configuration
build.sh                generates MobileHarmonica.xcworkspace with Tuist
```

The Xcode project, the workspace and `Derived/` are generated from `Project.swift` and not committed.
The app's test bundle also compiles `Core/Tests`, because Xcode will not run a package's test
target on a device.

## Conventions

- Names are plain English words in full, no abbreviations. One concept has one name everywhere.
- A type ends in its role: `UseCase`, `Repository`, `Mapper`, `ViewState`, `ViewModel`, `Presenter`. Entities have no suffix.
- A type used by another file has its own file. A feature folder keeps its entry points at the root and parts in subfolders.
- No comments. `MARK: - Public` and `MARK: - Private` on types past about forty lines.
- No accessibility modifiers, by the user's decision.
- `PlayHarmonicaUseCase` does the logging: `info` for what sounds and stops, `debug` for breath, bend and vibrato.

## Tests

- Names are `test_subject_whenCondition_outcome`. A unit test file is named after the type it tests, an integration test file after the feature or the part of it that it covers, and each ends in `UnitTests` or `IntegrationTests`.
- Integration tests run the real graph through `TestEnvironment` or `InstrumentEnvironment`, with doubles only where the process ends.
- The instrument is tested once, in the package. A rule each platform implements is tested on both.
- Whatever starts work has a test that it stops and one that it is released.
- Sound is checked on the real sampler, rendered offline.
- `FastPlayingBudgetIntegrationTests` is a budget that can fail, not a baseline.
- Wait on a named condition with `waitUntil`, never on a duration.
