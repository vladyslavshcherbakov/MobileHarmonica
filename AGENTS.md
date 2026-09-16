# MobileHarmonica

An expressive two-handed harmonica simulator for iPhone. The product plan is the GDD and
runs in six phases. Phase 4 is the current state: single touch, both breath directions off
the vertical axis, crossfaded sine wave synthesised at runtime, and a key slider. Real samples arrive in Phase 5 and the
user supplies them.

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

Only the audio layer logs: it is where the story lives, and where a failure
reaches the user as silence. `PlayHarmonica` deliberately logs nothing. Its early exits
fire once per touch event, which makes them raw samples rather than story, and the domain
has no log dependency to carry them. Give it one the first time a note-level question cannot
be answered from the audio log.

`Oscillator` crossfades. `soundTone(at:)` does not cut the previous note, it releases it
into a fading voice and raises a new one over 20 ms, and `silence()` fades the same way.
Two voices are enough: a third change during a fade drops the oldest, which is already near
zero. The render thread reads the voice set, renders a whole buffer, then writes it back
only when `changeCount` still matches, so a note started mid-buffer is never clobbered.

`AVAudioSession` is configured inside a detached task, never on the main thread. Calling
`setCategory` or `setActive` from the main thread raises the Hang Risk warnings that Xcode
reported after Phase 1, because either call can block while the session is active.

`Oscillator` is reached from the audio render thread and from the main thread. All of its
state sits behind an `OSAllocatedUnfairLock`, taken twice per buffer rather than once per
sample.

Generated files are not committed: `MobileHarmonica.xcodeproj` and
`Apps/MobileHarmonica/Info.plist` both come from `project.yml`. Run `xcodegen generate`
after changing it.

## Behaviour, as settled with the user

The harmonica is a ten hole diatonic in the key of C, Richter tuning.

    hole  1   2   3   4   5   6   7   8   9  10
    blow  C4  E4  G4  C5  E5  G5  C6  E6  G6  C7
    draw  D4  G4  B4  D5  F5  A5  B5  D6  F6  A6

From hole 7 upwards the draw reed is lower than the blow reed. That is the real Richter
layout, not a mistake.

The key slider transposes every reed by a whole number of semitones. The twelve keys run
from G, five semitones below C, to F sharp, six above, so C sits in the middle of the
slider and no key is shrill. The GDD asks for D and E flat to play along with the Cowboy
Bebop tracks; both are on the slider. Moving the slider while a note sounds re-sounds it in
the new key, through the same crossfade.

The key slider sits in a 44 point bar above the harmonica, so the harmonica no longer fills
the entire screen. The gesture reads its fractions from the harmonica's own area, not the
window, so the centre line stays at the middle of the playable strip.

The horizontal centre line splits blow from draw. A finger on the line or above it blows,
a finger below it draws. The boundary belongs to blow, by the user's decision.

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

Audio interruptions are handled only through `scenePhase`. A phone call normally takes the
app out of `.active`, so the note stops, but nothing observes
`AVAudioSession.interruptionNotification`, and a route change such as unplugging headphones
is not handled at all.

UI strings are not localized. `HarmonicaPresenter` holds English literals.

Mouth width is not modelled. On a real harmonica the mouth covers one to four adjacent
holes and every covered reed sounds at full volume; position decides which holes are
covered, width decides how many. There is no position-based blend between neighbours.
Modelling width needs a polyphonic `AudioEngineProtocol`, which is why it is not in
Phases 1 to 4. The user raised it and it is theirs to place.
