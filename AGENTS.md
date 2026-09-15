# MobileHarmonica

An expressive two-handed harmonica simulator for iPhone. The product plan is the GDD and
runs in six phases. Phase 1 is the current state: single touch, blow only, horizontal axis
only, sine wave synthesised at runtime.

## Constraints

Platforms and minimum OS: iOS 17.0. iPhone only (`TARGETED_DEVICE_FAMILY = 1`).
Landscape only, both orientations, enforced in the generated Info.plist.

Targets: `MobileHarmonica` (app). No test target yet.

What shares storage, and what runs on another device: nothing. One app, no persistence,
no paired device, no extension.

## Rules chosen

Shared code becomes a module when: undecided. There is one app and no shared code, so the
question has not come up. Every folder is still written as if it were a module.

Naming register: plain English, as in writing-swift-code.

Test policy: no tests in Phase 1, by the user's decision. From Phase 2, behaviour tests
through real screens, one bundle hosted by the app.

Tools allowed: XcodeGen. AudioKit through Swift Package Manager from Phase 2. Nothing else
without asking.

Audio is reached only through `AudioEngineProtocol`. Nothing under `Domain/` or `Features/`
imports AVFoundation, and nothing will import AudioKit when it arrives. The implementation
behind the protocol is the only thing that changes between phases.

Swift language mode 5 (`SWIFT_VERSION = 5.9`), strict concurrency left at its default of
`minimal`. View models and the coordinator are plain `ObservableObject` and are not marked
`@MainActor`, because a `@MainActor` view model cannot be constructed inside the
`@autoclosure` that `@StateObject` takes. SwiftUI drives all of them from the main actor.

Logging goes through `TimestampedLog`, which prefixes every line with a fixed-format UTC
timestamp to the millisecond so that lines can be ordered without depending on the reader's
locale. The composition root owns the subsystem and passes it in, so no layer reads
`Bundle.main` itself.

In Phase 1 only the audio layer logs: it is where the story lives, and where a failure
reaches the user as silence. `BlowIntoHarmonica` deliberately logs nothing. Its early exits
fire once per touch event, which makes them raw samples rather than story, and the domain
has no log dependency to carry them. Give it one the first time a note-level question cannot
be answered from the audio log.

`Oscillator` is reached from the audio render thread and from the main thread. All of its
state sits behind an `OSAllocatedUnfairLock`, taken twice per buffer rather than once per
sample.

Generated files are not committed: `MobileHarmonica.xcodeproj` and
`Apps/MobileHarmonica/Info.plist` both come from `project.yml`. Run `xcodegen generate`
after changing it.

## Phase 1 behaviour, as settled with the user

The harmonica is a ten hole diatonic in the key of C, Richter tuning. Phase 1 plays the
blow row only: C4 E4 G4 C5 E5 G5 C6 E6 G6 C7. Ten holes give three pitch classes, so
Phase 1 plays a C major arpeggio and no melody. The draw row arrives in Phase 2.

Hole 1 is on the left. The ten segments divide the full width of the safe area equally.

A hole sounds the moment the finger touches it, before any movement.

Lifting the finger silences the note.

A finger that leaves the strip horizontally silences the note. Returning to the strip
sounds the hole again.

A second finger is ignored. The first finger stays in control.

The screen shows ten numbered plates on a dark background and highlights the sounding one.

The app sounds through the silent switch (`AVAudioSession` category `.playback`).

An incoming call or a move to the background silences the note.

When the audio engine fails to start, the screen says so. It never fails quietly.

`HarmonicaViewState` is an enum over the three situations the screen can be in:
`preparingSound` while the engine starts, `ready` with the ten holes, `soundUnavailable`
with a message. Returning to the foreground runs `prepareSound()` again, so a screen that
failed once can recover.

`AppRoute.harmonica` names the only screen that exists and nothing pushes it yet. The scene
root renders the harmonica directly and installs no `navigationDestination`, because a
destination mapping `.harmonica` to a second screen would build a second audio engine.
Add the destination together with the second screen.

## Open questions

Who owns the breath direction. GDD section 1 gives inhale and exhale to the right hand,
while Phase 2 gives them to the sign of the left finger's Y. The phases win unless the user
says otherwise. Decide before Phase 2.

Which way Y points. SwiftUI's y grows downward and the GDD writes "above the centerline
(Y > 0)", measuring upward from the centre. The GDD's convention will be an explicitly
named value in code, never a raw `location.y`. Decide before Phase 2.

Audio interruptions are handled only through `scenePhase`. A phone call normally takes the
app out of `.active`, so the note stops, but nothing observes
`AVAudioSession.interruptionNotification`, and a route change such as unplugging headphones
is not handled at all.

UI strings are not localized. `HarmonicaPresenter` holds English literals.

Phase 1 clicks at every hole boundary. That follows from the GDD's "immediate cut of the
old note and instant playback of the next note" on a sine wave with non-zero amplitude.
Phase 3 removes it with crossfades. It is not a defect.
