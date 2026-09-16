# MobileHarmonica

An expressive two-handed harmonica simulator for iPhone. The product plan is the GDD and
runs in six phases. Phase 4 is the current state, with multi-touch pulled forward from the
user's own design: several fingers, both breath directions off the vertical axis, a
crossfaded polyphonic sine wave synthesised at runtime, and a key slider. Real samples arrive in Phase 5 and the
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
`@MainActor`, because a `@MainActor` view model needs `MainActor.assumeIsolated` to be
constructed inside the `@autoclosure` that `@StateObject` takes, and a bridge at every other
non-isolated callback as well: the `Binding` setter a `Slider` takes, and the closure a
`UIViewRepresentable` hands to its `UIView`.

The price of leaving it off is that nothing checks which thread publishes. A nonisolated
`async` function runs its body on the cooperative pool, not on the caller's actor, so every
`async` function that ends by publishing state must be marked `@MainActor` by hand. That is
why `HarmonicaViewModel.prepareSound()` and `HarmonicaScreen.prepareOrSilence(for:)` carry
the annotation: without it the continuation after `await` resumes off the main thread and
Combine reports publishing from a background thread. Every other caller of `show()` is
synchronous and reached from a main-thread callback.

Marking the whole view model `@MainActor` would hand that check to the compiler instead.
It is worth doing the next time this class grows an `async` method.

Logging goes through `TimestampedLog`, which prefixes every line with a fixed-format UTC
timestamp to the millisecond so that lines can be ordered without depending on the reader's
locale. The composition root owns the subsystem and passes it in, so no layer reads
`Bundle.main` itself.

Only the audio layer logs: it is where the story lives, and where a failure
reaches the user as silence. `PlayHarmonica` deliberately logs nothing. Its early exits
fire once per touch event, which makes them raw samples rather than story, and the domain
has no log dependency to carry them. Give it one the first time a note-level question cannot
be answered from the audio log.

`Oscillator` crossfades and is polyphonic. `soundTones(at:)` does not cut anything: it
drops the target gain of every voice whose pitch is no longer wanted, and raises a voice for
every pitch that is not already rising, over 20 ms. A pitch that is still wanted keeps its
voice, so adding a finger does not re-attack the note already held. `silence()` fades them
all. The render thread reads the bank, renders a whole buffer, then writes it back only when
`changeCount` still matches, so a note started mid-buffer is never clobbered.

That read-modify-write copies the voice array, so the first mutation in a buffer triggers one
small copy-on-write allocation on the render thread, about ninety times a second. Allocating
there is not real-time safe in principle. It is accepted because the alternative is a
manually allocated `os_unfair_lock` held across the whole buffer, and because the array holds
at most a handful of voices. Revisit it if the audio ever glitches under load.

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

The key slider sits in a 44 point bar above the harmonica and the tone shaping zone, so the
harmonica no longer fills the entire screen. The gesture reads its fractions from the harmonica's own area, not the
window, so the centre line stays at the middle of the playable strip.

Every finger on the harmonica sounds its own hole. Two fingers on adjacent holes are the
chord a mouth makes; two fingers apart are the tongue block split a player makes by
blocking the holes between them. Two fingers on one hole sound one note, not two.

The topmost finger decides the breath for all of them, by the user's decision. On the
centre line or above it, every sounding hole blows; below it, every one draws. Nobody can
blow and draw at once, so one finger has to win and the highest one does. The boundary
belongs to blow.

The vertical distance from the centre line sets how hard the harmonica is blown, taken from
the same finger that decides the breath, because one mouth gives one airflow to every hole
at once. On the line the gain is 0.2 rather than 0, by the user's decision, so the
instrument is always audible; at the top or bottom edge it is 1.

The curve is compressive: it rises fast near the line and flattens towards the edge, which
is the half of a real reed's response a sine can carry. The other half it cannot. A real
reed reaches its excursion limit and turns extra pressure into harmonics, so it gets dirtier
rather than louder, and a sine has no harmonics to add. That waits for the sample layers of
Phase 5, which ride on this curve rather than replace it.

Intensity changes on every touch move, while the set of sounding pitches changes rarely, so
they travel by separate methods. `soundTones(at:)` replaces the voices and bumps
`changeCount`; `changeIntensity(to:)` writes one number to its own lock, which the render
thread reads fresh each buffer and ramps towards over the same 20 ms. Routing intensity
through the voice bank instead would invalidate the render's write-back on nearly every
buffer and the note would stutter.

Nothing caps how many holes sound at once. A mouth reaches about four; ten fingers reach
ten. The mix is divided by the total gain of the sounding voices, so ten notes cannot clip,
and one note is as loud as it was before.

Touches arrive through `TouchArea`, a `UIViewRepresentable` over a `UIView` with
`isMultipleTouchEnabled`. SwiftUI's `DragGesture` reports one finger and no contact radius,
so it cannot carry this. The view reports the whole set of touches still down on every
change, and an empty set is what silences the harmonica.

Hole 1 is on the left. The ten segments divide the full width of the safe area equally.

A hole sounds the moment the finger touches it, before any movement.

Lifting the finger silences the note.

A finger that leaves the strip horizontally silences the note. Returning to the strip
sounds the hole again.

The tone shaping zone takes the right 28 per cent of the strip. A finger there shapes the
sound instead of sounding a reed: down bends the pitch, right deepens the vibrato. The
topmost finger in the zone drives it, the same rule the harmonica uses, because
`UIEvent.allTouches` is a set and has no order to take a first finger from. Lifting every
finger out of the zone returns the pitch and the vibrato to rest.

A bend is not a note of its own. It is the sounding reed pulled down towards the other reed
of the same hole, and it stops a semitone short of reaching it, so each reed has its own
range: three semitones on hole 3 draw, two on hole 2 draw and hole 10 blow, one on most of
the rest, and none at all on holes 5 and 7 where the two reeds are already a semitone apart.
`RichterTuning` derives that range from the two reeds rather than holding a second table.
Holes 1 to 6 bend on the draw and 7 to 10 on the blow, which follows from the same
"perevertysh" that makes the draw reed lower from hole 7 up.

Bending is cheaper on a synthesised tone than on a sample: the frequency is already a
parameter, so a bend is one multiplication by `2^(-semitones/12)`. The GDD routes Phase 6
through `sampler.pitchBend` because a sample has to be dragged off its recorded pitch.

Bend and vibrato travel like intensity, by their own methods and their own locks, because
they change on every touch move. A voice carries the semitones it can bend and the render
thread applies the shared fraction to each voice once per buffer, so the set of sounding
pitches still changes rarely and the render's write-back is not invalidated. Vibrato is one
shared LFO at 5.5 Hz reaching 3 per cent of the frequency, about 51 cents, at full depth.

The screen shows ten numbered plates on a dark background and highlights the sounding ones.

Each plate is split in half by shade rather than by a drawn line: the blow half on top at
full colour, the draw half below it dimmed to 0.55. The split is the centre line, so the
boundary is visible on every plate at once instead of on one thin rule across them.

A hollow circle follows each finger, drawn where the finger actually is rather than snapped
to the hole it plays, so the distance to a hole boundary and to the centre line stays
visible. The finger deciding the breath is drawn in white and the rest in grey. A finger
that has left the strip sideways makes no sound and gets no circle.

The circles live in the view's own state. They mark where a touch is, which is the view's
own geometry, so nothing about them reaches the presenter and a finger moving inside one
hole still publishes no view state.

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

A finger that has left the strip sideways still decides the breath for the fingers that
remain, because the breath is taken from the topmost of all touches while only the touches
on the strip sound a hole. It then has no circle, so nothing on screen says which finger
decided. Deciding the breath among the sounding fingers only would fix both, and is a change
to behaviour the user has not asked for.

Where the wah filter goes is undecided. The zone's one finger already carries bend on its
vertical axis and vibrato on its horizontal one, so a third parameter needs somewhere else:
a second finger in the zone, the device's tilt, or giving the horizontal axis to wah and
making vibrato automatic. Deciding it costs nothing today, because a resonant filter sweeping
over a sine has no harmonics to emphasise and cannot be heard at all until the samples of
Phase 5 arrive.

Contact radius is not used. `UITouch.majorRadius` exists and `TouchTrackingView` is already
the place that could read it, but nobody has measured whether it varies usefully on an
iPhone. `UITouch.force` is not an option at all: 3D Touch hardware ended with the iPhone XS.

Mouth width as a separate parameter is not modelled. On a real harmonica the mouth covers one to four adjacent
holes and every covered reed sounds at full volume; position decides which holes are
covered, width decides how many. There is no position-based blend between neighbours.
Modelling width needs a polyphonic `AudioEngineProtocol`, which is why it is not in
Phases 1 to 4. The user raised it and it is theirs to place.
