# MobileHarmonica

Expressive harmonica simulator for iPhone. The screen is the instrument: fingers on the left
strip sound reeds, a square zone on the right shapes the tone. Landscape only.

The product plan is the GDD, in six phases. **Current state: phase 4 complete, with
multi-touch and the phase 6 shaping zone pulled forward.** Sound is synthesised; real
samples arrive in phase 5 and the user supplies them.

## Contents

1. [Quick start](#quick-start)
2. [Constraints](#constraints)
3. [Repository layout](#repository-layout)
4. [Architecture](#architecture)
5. [Instrument reference](#instrument-reference)
6. [Interaction model](#interaction-model)
7. [Audio pipeline](#audio-pipeline)
8. [Concurrency contract](#concurrency-contract)
9. [Conventions](#conventions)
10. [Known limits](#known-limits)
11. [Open questions](#open-questions)

## Quick start

```sh
xcodegen generate          # after any change to project.yml
open MobileHarmonica.xcodeproj
```

Scheme `MobileHarmonica` builds the app and runs `MobileHarmonicaTests`.

`MobileHarmonica.xcodeproj` and `Apps/iOS/Info.plist` are generated and not committed.

## Constraints

| | |
|---|---|
| Platform | iOS 17.0, iPhone only (`TARGETED_DEVICE_FAMILY = 1`) |
| Orientation | Landscape only, both directions, enforced in the generated Info.plist |
| Language | Swift 5.9, language mode 5, strict concurrency `minimal` |
| Build | XcodeGen via `project.yml`. No other tooling without asking |
| Dependencies | None. AudioKit through SPM is planned for phase 5 |
| Persistence | None. No storage, no paired device, no extension |
| Targets | `MobileHarmonica` (app), `MobileHarmonicaTests` (unit tests hosted by it) |

## Repository layout

```
Apps/iOS/
  App/          entry point and composition root
  Domain/       Entities, Protocols, UseCases. Imports Foundation only
  Audio/        AudioEngineProtocol implementation
  Features/     one folder per feature: view state, presenter, view model, views
  Logging/      TimestampedLog
  Navigation/   coordinator and routes
  Tests/        Harmonica/ for behaviour, Support/ for doubles and helpers
project.yml
AGENTS.md
```

The app target's sources are `Apps/iOS` with `Tests` excluded. The test bundle generates its
own Info.plist through `GENERATE_INFOPLIST_FILE`; without one Xcode refuses to sign it.

One app, so no modules. Every folder is written as if it were one: public on the boundary,
imports pointing inward.

## Architecture

Clean layering. A rule lives in exactly one layer.

| Layer | Path | May import | Owns |
|---|---|---|---|
| Domain | `Domain/` | Foundation | Entities, the protocols it needs, the use case |
| Audio | `Audio/` | AVFoundation, os | The synthesiser behind `AudioEngineProtocol` |
| Presentation | `Features/` | SwiftUI, UIKit, Combine | View state, presenter, view model, views |
| Composition | `App/` | everything | Building the graph |

**Enforced boundaries.** Nothing under `Domain/` or `Features/` imports AVFoundation or will
import AudioKit. No domain type imports `os`; it reaches the log through `LogProtocol`. Only
values cross a boundary.

**Composition.** `CompositionRoot` takes the audio engine and the log as parameters and
assembles everything else. `MobileHarmonicaApp` builds the real leaves and hands them in, so
a test assembles the app's own graph with doubles in their place rather than a second
assembly that drifts.

**Why one use case.** `PlayHarmonica` covers playing, changing key and shaping the tone,
because all three read and write one piece of state: which reeds are sounding now.
`changeKey` re-sounds them, `shapeTone` needs their bend range. Split into three and all
three would need a shared instrument object, which is this use case under another name. Split
it only if that state moves into a `Harmonica` entity first.

## Instrument reference

Ten hole diatonic, Richter tuning, key of C at slider position 5.

| hole | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| blow | C4 | E4 | G4 | C5 | E5 | G5 | C6 | E6 | G6 | C7 |
| draw | D4 | G4 | B4 | D5 | F5 | A5 | B5 | D6 | F6 | A6 |
| bend | −1 draw | −2 draw | −3 draw | −1 draw | none | −1 draw | none | −1 blow | −1 blow | −2 blow |

From hole 7 up the draw reed is lower than the blow reed. That is the real layout, not a bug.

**Bend.** Not a note of its own: the sounding reed is pulled down towards the other reed of
the same hole and stops a semitone short, so the range is the interval between the two reeds
minus one. `RichterTuning` derives it from the two reeds rather than holding a second table.
Eight of the twenty reeds bend.

**Key slider.** Twelve keys, G (−5 semitones) to F♯ (+6), C in the middle so neither end is
shrill. Transposing preserves intervals, so bend ranges are unchanged in every key.

## Interaction model

| Control | Input | Effect |
|---|---|---|
| Hole | Finger x on the strip, right of the square | Sounds that hole. Every finger sounds its own |
| Breath direction | y of the **topmost** finger | On or above the centre line blows, below draws |
| Breath intensity | \|y\| of the same finger | 0.2 on the line to 1.0 at the edge |
| Bend | Finger y in the square | 0 at the top to the reed's full range at the bottom |
| Vibrato | Finger x in the square | 0 at the left to 51 cents at the right |
| Key | Slider in the top bar | Transposes every reed |
| Zone size | Pinch on the square | Resizes it, trading width with the strip |

**One breath for the whole instrument.** One mouth gives one airflow, so the topmost finger
decides direction and intensity for every sounding hole. The boundary belongs to blow.

Only fingers on the strip take part. A finger that has slid off the side neither sounds a
hole nor decides anything, and the arbitration passes to the topmost of those left, so the
white circle always marks a finger that is actually playing. `PlayHarmonica` and the screen
both filter on `PositionOnHarmonica.isOnTheHarmonica`, which is one rule in one place.

**Chords are the point.** Two fingers on adjacent holes are the chord a mouth makes; two
apart are a tongue block split. Two on one hole sound one note. Nothing caps the count.

**The square sits on the left**, the strip on the right, for a right-handed player: the right
hand picks holes, the left thumb shapes. Hole 1 stays at the left end of the strip, which is
where it is on the instrument.

**The square.** Natural side is `min(height, width × 0.22)`, so both axes are comparable.
A pinch on the square resizes it between 0.45 and 2.0 of that, capped by the strip height,
which on a 844 by 340 strip runs from 84 to 340 points and moves a hole between 70 and 44.
The recogniser sits on the square's own `TouchTrackingView` and nowhere else: it cancels the
touches under it, which is right when resizing and wrong on the strip, where two fingers are
a chord. The size is not stored, so it returns to its natural side on the next launch. The topmost
finger in it drives both. Lifting out returns pitch and vibrato to rest. When the sounding
reed cannot bend, the bend label dims; the vibrato label does not, because the horizontal
axis still works.

**Safe area.** Only the leading edge is ignored, and only the square sits there. The strip
keeps its trailing and bottom insets, so no plate goes under the notch or under the home
indicator, and the draw half of every hole stays reachable.

The ignore belongs on the screen's outermost view, above the
`frame(maxWidth: .infinity)`. Put it on a view nested below that frame and the width is
already fixed to the safe area by the time the ignore is read, so nothing expands and the
square stops short of the glass. The key bar takes the inset back with
`safeAreaPadding(.leading)` rather than keeping its own safe area.

**Touches** arrive through `TouchArea`, a `UIViewRepresentable` over a `UIView` with
`isMultipleTouchEnabled`, because `DragGesture` reports one finger and no contact radius.

> `UIEvent.allTouches` is every touch in the application, not the ones this view received.
> `TouchTrackingView` filters on `touch.view === self`. Without that filter the strip and the
> square each see the other's fingers in their own coordinates, and a finger on the strip
> lands at a negative x inside the square, wins the topmost arbitration and pins vibrato to
> zero.

## Audio pipeline

`Oscillator` is polyphonic and crossfading. A voice is a sine with a frequency, a gain, a
target gain and the semitones it can bend.

| Call | Frequency | Effect |
|---|---|---|
| `soundTones(_:)` | On reed change | Drops the target gain of unwanted voices, raises new ones over 20 ms, bumps `changeCount` |
| `changeIntensity(to:)` | Every touch move | One number in its own lock |
| `changeBend(to:)` | Every touch move | One number in its own lock |
| `changeVibrato(to:)` | Every touch move | One number in its own lock |
| `silence()` | Lift | Fades every voice |

**Why the split.** Continuous parameters change on every touch event while the set of
pitches changes rarely. Routing them through the voice bank would bump `changeCount` on
nearly every buffer, the render's write-back would be rejected and the note would stutter.

**Crossfade, not overlap.** 20 ms linear gain, enough to remove the click at a hole boundary.
It is not a model of the instrument: a real mouth covers both holes for a moment and both
sound at full volume. See [Known limits](#known-limits).

**Mixing.** The sum is divided by the total gain of the sounding voices, then by the breath
gain, so ten notes cannot clip and one note is as loud as it was.

**Bend** is one multiplication by `2^(-semitones/12)`, applied per voice once per buffer.
Cheaper than a sample, which has to be dragged off its recorded pitch.

**Vibrato** is one shared LFO at 5.5 Hz reaching 3 per cent of the frequency, about 51 cents.

## Concurrency contract

**The oscillator** is reached from the render thread and the main thread. All state sits
behind `OSAllocatedUnfairLock`. The render thread reads the bank, renders a whole buffer,
writes it back **only if `changeCount` still matches**, so a note started mid-buffer is never
clobbered.

**Known cost.** That read-modify-write copies the voice array, so the first mutation in a
buffer triggers one small copy-on-write allocation on the render thread, about ninety times
a second. Not real-time safe in principle. Accepted: the alternative is a manually allocated
`os_unfair_lock` held across the whole buffer, and the array holds a handful of voices.
Revisit if the audio glitches under load.

**`AVAudioSession`** is configured inside a detached task, never on the main thread.
`setCategory` and `setActive` can block while the session is active, which is the
`AVAudioSession Hang Risk` warning.

**Publishing.** View models and the coordinator are plain `ObservableObject`, not
`@MainActor`. A `@MainActor` view model would need `MainActor.assumeIsolated` inside the
`@autoclosure` that `@StateObject` takes, plus a bridge at the `Slider` binding and the
`UIViewRepresentable` callback.

> The price: nothing checks which thread publishes. A nonisolated `async` function runs its
> body on the cooperative pool, not the caller's actor, so **every `async` function that ends
> by publishing must be marked `@MainActor` by hand**. That is why
> `HarmonicaViewModel.prepareSound()` and `HarmonicaScreen.prepareOrSilence(for:)` carry it.
> Every other caller of `show()` is synchronous and reached from a main-thread callback.
> Marking the whole view model `@MainActor` hands the check to the compiler; do it the next
> time this class grows an `async` method.

**Control precision.** `ControlPrecision` quantises intensity, bend and vibrato to a
hundredth. One per cent of gain and three cents of bend are both below hearing, and without
it a finger that barely moves fires the engine and the log on every touch event.

## Conventions

**Code.** Plain English names, no comments or documentation comments, one level of
abstraction per function. `MARK: - Public` and `MARK: - Private` on any type past roughly
forty lines, and a mark naming every other type or extension in a file.

**Logging.** `PlayHarmonica` tells the story, because only it knows the hole, the breath and
the key; the engine sees frequencies nobody can trace to a finger.

| Level | Content |
|---|---|
| `info` | What starts and stops sounding, key changes, audio engine outcomes |
| `debug` | Breath intensity, bend with the semitones actually available, vibrato |

Every line carries a fixed-format UTC timestamp to the millisecond, so lines order without
depending on the reader's locale.

**Tests.** One bundle hosted by the app. Names are `test_subject_whenCondition_outcome`.
Files are named for the promise, not the type.

Sound is the one guarantee no screen can show, so it is checked where it is visible: on the
real `Oscillator`, rendered offline into an `AudioBufferList` by `RenderedSound`, with pitch
read back from rising zero crossings. Thresholds are chosen so the reader can do the
arithmetic: 440 Hz swung by 3 per cent covers 26 Hz, so a spread over 5 Hz is vibrato and
under 2 Hz is the estimator wandering; B4 pulled three semitones is A♭4, 415.30 Hz.

Everything else drives the app's own graph with the leaves swapped.

## Known limits

**No mouth width.** A real mouth covers one to four adjacent holes and every covered reed
sounds at full volume. Position decides which holes, width decides how many, and there is no
position-based blend between neighbours. This is also why the horizontal crossfade is not
physical: a real slide overlaps, it does not fade. Modelling width needs no new audio work,
the engine is already polyphonic; it needs a control surface and the user's decision on where.

**No contact radius.** `UITouch.majorRadius` exists and `TouchTrackingView` could read it,
but nobody has measured whether it varies usefully on an iPhone. `UITouch.force` is not an
option: 3D Touch hardware ended with the iPhone XS.

**No wah.** A resonant filter sweeping a sine has no harmonics to emphasise, so it cannot be
heard before the samples of phase 5.

**Audio interruptions** are handled only through `scenePhase`. A call takes the app out of
`.active` and the note stops, but nothing observes
`AVAudioSession.interruptionNotification`, and a route change such as unplugging headphones
is not handled.

**UI strings are not localized.** `HarmonicaPresenter` holds English literals.

**`AppRoute.harmonica`** names the only screen and nothing pushes it. The scene root renders
the harmonica directly and installs no `navigationDestination`, because mapping `.harmonica`
to a destination would build a second audio engine. Add the destination with the second
screen.

## Open questions

| Question | Blocked on |
|---|---|
| Where the wah control lives: second finger in the square, device tilt, or taking the horizontal axis from vibrato | Nothing audible until phase 5 samples |
| Where mouth width lives: which phase, and which control surface | The user's decision |
| Whether vibrato rate becomes a third axis | Needs a free control |
