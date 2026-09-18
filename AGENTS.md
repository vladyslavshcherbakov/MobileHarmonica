# MobileHarmonica

Expressive harmonica simulator for iPhone. The screen is the instrument: fingers on the left
strip sound reeds, a square zone on the right shapes the tone. Landscape only.

The product plan is the GDD, in six phases. **Current state: phase 5, with multi-touch and
the phase 6 shaping zone pulled forward.** Sound comes from recorded harmonica notes, one WAV
per pitch, which the user supplies and which are not committed.

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

`MobileHarmonica.xcodeproj` and `Apps/iOS/Info.plist` are generated and not committed. Neither
are the WAV files: `Apps/iOS/Audio/Samples/` ships empty and the app says sound is unavailable
until they are copied in. See the README there.

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
  Audio/        AudioEngineProtocol implementation, and Samples/ for the WAV files
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

**One value out.** Every action on `PlayHarmonica` returns the whole `Harmonica`: the key,
the style, and a `SoundingReed` per sounding hole carrying the reed's own pitch, how far it
can bend and how far it is bent. What the player hears is derived from those three, never
stored beside them, so the note on screen cannot disagree with the reed behind it. The view
model passes that one value to the presenter and assembles nothing.

The shape before this returned the sounding holes and left the view model to read the key,
the style and a `bendableSemitones` off the use case afterwards. Nothing bound the four
together, `bendableSemitones` was a view question answered by the domain, and every new thing
the screen showed added a parameter.

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
| overbend | +3 blow | +4 blow | +5 blow | +3 blow | +2 blow | +3 blow | +2 draw | +3 draw | +3 draw | +4 draw |

From hole 7 up the draw reed is lower than the blow reed. That is the real layout, not a bug.

**Bend.** Not a note of its own: the sounding reed is pulled down towards the other reed of
the same hole and stops a semitone short, so the range is the interval between the two reeds
minus one. Eight of the twenty reeds bend.

**Overbend.** The opposite move, and the complement: the reed matching the airflow is
silenced and the other one sounds in its opening mode, a semitone above its own pitch. It is
available exactly where a bend is not, because a bend needs the higher reed of a chamber and
an overbend the lower. Blowing into a chamber whose blow reed is lower gives an **overblow**,
holes 1 to 6; drawing where the draw reed is lower gives an **overdraw**, holes 7 to 10. The
shift from the sounding reed is the interval between the reeds plus one, so it runs from two
semitones to five, not a fixed amount.

Together they leave 18 of the 20 reeds responsive. Hole 5 draw and hole 7 blow stay dead:
their reeds are a semitone apart, so the bend range is zero and they are the higher reed, so
there is no overbend either. `RichterTuning` derives both ranges from the two reeds rather
than holding a second table.

**Key slider.** Twelve keys, G (−5 semitones) to F♯ (+6), C in the middle so neither end is
shrill. Transposing preserves intervals, so bend ranges are unchanged in every key.

## Interaction model

| Control | Input | Effect |
|---|---|---|
| Hole | Finger x on the strip, right of the square | Sounds that hole. In `fingers` style every finger sounds its own; in `mouth` style only the topmost plays, and it sounds every hole its contact circle touches |
| Breath direction | y of the **topmost** finger | On or above the centre line blows, below draws |
| Breath intensity | \|y\| of the same finger | 0.2 on the line to 1.0 at the edge |
| Bend | Finger y below the middle of the square | 0 at the middle to the reed's full range at the bottom |
| Overbend | Finger y above the middle of the square | 0 at the middle to the reed's full shift at the top |
| Vibrato | Finger x in the square | 0 at the left to 51 cents at the right |
| Key | Slider in the top bar | Transposes every reed |
| Zone size | Pinch on the square | Resizes it, trading width with the strip |
| Playing style | Segmented control in the top bar | `fingers` or `mouth` |

**Two playing styles.** `fingers` is the default and unchanged: one finger, one hole, as many
fingers as the player has. `mouth` takes the topmost finger only and sounds every hole the
reported contact circle overlaps, which is `UITouch.majorRadius` either side of the centre.
Breath direction and intensity come from the centre of that contact, so an edge of the pad
crossing the centre line changes nothing. Switching style silences whatever was sounding.

The radius is taken literally, with no multiplier, and it is deliberately on trial: at the
natural square size a hole is about 66 points and a fingertip reports something like 8 to 30,
so a contact covers well under one hole and reaches two only by straddling a boundary. Two
things measure it. The finger circle is drawn at the reported radius in `mouth` style instead
of the fixed 56 points, and `PlayHarmonica` logs the width in hole widths at debug level,
deduplicated to a hundredth. Decide the multiplier from those numbers, not from an estimate.

**The note row.** Two lines above each plate, 30 points tall, taken off the plates rather
than off the square. A hole that is sounding names its note, rounded to the nearest semitone,
and under it, when something shifted the pitch, the reed it started from and what shifted it:
`C♯5` over `(D5 bend)`. A hole that is silent names nothing, so the row is as quiet as the
playing.

The key is not an effect, so the reed in brackets is the reed in the current key: in D the
first hole blows D4 and the bracket says D4. Vibrato is not an effect either, for a different
reason. It does move the frequency, by about 51 cents, but it moves it back and forth around
the reed, so there is no steady note to round.

**The square's vertical axis rests in the middle.** Down bends, up overbends, and on any one
hole in one breath direction exactly one half is live, so the other half's label dims. Each
half keeps half the travel; the square is pinch-resizable, so travel is recoverable and the
convention that up is higher is not.

`PitchShaping` is the signed fraction the axis gives, −1 at the bottom and +1 at the top, and
it splits itself into a `BendDepth` and an `OverbendDepth`. The bend is continuous, the
overbend is not: nothing below half travel, the whole overbend above it. An overblow does not
slide in on the instrument, it pops once the reed goes over, so there is no continuous version
to offer.

What is not instant is the player reshaping the mouth, roughly 50 to 150 ms by the rate of
vowel transitions in speech. That time is already modelled: it is how long the thumb takes to
travel up the axis, and the note stays plain the whole way, exactly as it does until the tract
passes its critical point. What follows is one reed dying while another catches, which is the
50 ms crossfade, not a pitch glide: two different reeds sound, so the pitch never visits the
notes in between.

A `smooth` mode that slid into the overbend was built and removed. It was justified as easier
to play and it is not: to land the overbend's real pitch it needs the thumb parked at the very
top, while the threshold only needs the thumb pushed past halfway. All it added was an upward
pitch slide the instrument does not have, and the upward slide that does exist, releasing a
bend, is already on the lower half.

The threshold has a second job: it is a deadband around rest. Without it a thumb resting just
above the middle would flicker the note between plain and overbent. Travel above the threshold
does nothing, and that is where the stretch of ROADMAP item 6 would go.

An overbend shifts every sounding reed at once, each by its own range, the same rule the bend
already follows. One mouth cannot overblow a chord on the instrument, but a second rule for
chords would be a second rule for nothing.

**The demo plays itself through the instrument, not around it.** `PlayScore` turns each score
event into a finger position and puts it through `PlayHarmonica.play(at:)`, the same call a
real finger makes. Nothing about the tuning, the bend ranges or the breath rule is written a
second time, and everything the screen already shows keeps working: the plates light, the note
row names the note, a bend is a fraction of that reed's own range.

A score says a bend in **semitones**, not in axis travel, because a score should not know that
hole 3 draw bends three semitones and hole 4 draw bends one. `PlayScore` asks `RichterTuning`
for the range and divides. Each note is cut short by up to 50 ms so the next one re-attacks;
without that gap two of the same note in a row would be one long note, because `play(at:)`
sees the same reeds and does not re-sound.

A live finger stops the score, since both drive one instrument. Timing is `Task.sleep`, whose
jitter is a few milliseconds: fine for a demo, not for music. See ROADMAP item 3.

**A sounding plate lights only the half that is sounding**, the top for blow and the bottom
for draw, so the demo shows where to put a finger and which way to breathe. It used to light
both halves, which said which hole and not which breath.

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
The recogniser is created only when a pinch handler is passed, which the strip never does. It
cancels the touches beneath it, which is right when resizing and ruinous on the strip: two
fingers there are a chord, and a recogniser attached to every touch view silenced them
mid-phrase as soon as the pinch recognised. The size is not stored, so it returns to its natural side on the next launch. The topmost
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

`Oscillator` is polyphonic and crossfading. A voice is a recorded note read at a variable
rate, with a frequency, a gain, a target gain and the semitones it can bend. It was a sine
until phase 5, and the change was one line: a table read with linear interpolation instead of
`sin(phase)`, position instead of phase. Everything around it survived unchanged.

| Call | Frequency | Effect |
|---|---|---|
| `soundTones(_:as:)` | On reed change | Drops the target gain of unwanted voices, raises new ones over the change's crossfade |
| `changeIntensity(to:)` | Every touch move | One number in its own lock |
| `changeBend(to:)` | Every touch move | One number in its own lock |
| `changeVibrato(to:)` | Every touch move | One number in its own lock |
| `silence()` | Lift | Fades every voice |

**Why the split.** Continuous parameters change on every touch event while the set of
pitches changes rarely. Routing them through the voice bank would rewrite the voice array on
nearly every buffer for a number that is one `Double` wide.

**Crossfade, not overlap.** Linear gain, and the caller says which kind of change it is,
because the two take different times. `.slide` is 20 ms, enough to remove the click at a hole
boundary and short enough that a fast run is not smeared. `.newReed` is 50 ms, for an overbend
engaging or releasing, where one reed really does hand over to another. The domain names the
event and the audio layer owns the milliseconds.

The slide is not a model of the instrument: a real mouth covers both holes for a moment and
both sound at full volume. See [Known limits](#known-limits).

**The recordings.** `RecordedHarmonica` reads every WAV in the bundle's `Samples` folder at
`prepare()`, mixes each to mono and appends it to one contiguous `[Float]`, so nothing is
streamed or decoded while the audio runs. A `RecordedNote` says where its frames start and
where its loop is; all of it is trivially copyable, so a voice carries one by value and the
render thread never retains anything.

`SampleBank.nearest(to:)` picks the recording closest in pitch, measured in octaves rather
than hertz, and the voice reads it at `wanted ÷ recorded` times speed. The library is one
harmonica in A, whose scale leaves every chromatic pitch within a semitone of some recording,
so nothing is ever stretched further than that except by a bend. Stretching moves the formants
with the pitch, which is what a real bent reed does anyway.

**The loop is seconds 1 to 4 of each file**, chosen rather than read from the library's EXS
mapping, and frames past second 4 are never loaded. A note plays from frame 0, so it keeps its
recorded attack, then repeats that window for as long as the finger is down. A file too short
to hold the window throws and names itself.

**Mixing.** The sum is divided by the total gain of the sounding voices, then by the breath
gain, so ten notes cannot clip and one note is as loud as it was.

**Bend** is one multiplication by `2^(-semitones/12)`, applied per voice once per buffer.
Cheaper than a sample, which has to be dragged off its recorded pitch.

**The overbend is not a parameter.** It changes which reed sounds, so it goes through
`soundTones` as a different pitch and crossfades, the same event as moving to another hole.
The engine never hears the word: the domain computes the overbent pitch and sends it as a tone
with no bend range, because an overblow cannot then be bent down.

It was a parameter first, a ratio stepped from 1 to `2^(semitones/12)` on one voice. That is
a pitch teleport with no amplitude transition, more abrupt than anything the instrument does.
Removing `smooth` is what made the better shape available: with only a threshold left, the
overbend engages rarely rather than on every touch move, so it belongs with the rare calls.

**Vibrato** is one shared LFO at 5.5 Hz reaching 3 per cent of the frequency, about 51 cents.

## Concurrency contract

**The oscillator** is reached from the render thread and the main thread. All state sits
behind `OSAllocatedUnfairLock`. The render thread reads the bank, renders a whole buffer
outside the lock, then takes the lock again and **merges its progress into whatever the bank
now holds**: phase, gain, breath gain and LFO phase per voice, matched by frequency, which is
unique because `sound(_:)` retargets a voice at a pitch it already holds instead of adding a
second one. A voice the render pass did not hold was either added mid-buffer or finished
fading out, and both start a cycle at phase zero.

**Why not write the buffer back whole.** It was, guarded by a `changeCount` that rejected the
write when the bank had been re-sounded meanwhile. Rejecting it threw away the phase the
buffer had just advanced, so the next buffer restarted the sine from where the discarded one
began: a jump of up to 26 times a normal adjacent-sample step, heard as a click. The window
is the render time, one or two per cent of a buffer period, which is why it was intermittent
and why stopping a note was the likeliest moment to hit it.

**Known cost.** Merging copies the voice array, so the render thread does one small
copy-on-write allocation per buffer, about ninety times a second. Not real-time safe in
principle. Accepted: the alternative is holding the lock across the whole buffer, which
blocks the main thread for the render's duration, and the array holds a handful of voices.
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

**No accessibility.** By the user's decision, nothing in this project carries an
accessibility modifier: no labels, values, identifiers or `accessibilityHidden`. The strip is
a raw multi-touch surface where a note is a finger held at a position, which VoiceOver's
gesture model cannot drive at all, so the annotations on the plates never made the instrument
playable. Do not add them back, including the identifiers a UI test bundle would key on;
there is no UI test target, and if one arrives it gets its identifiers then.

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

**Mouth width is only as wide as a fingertip.** `mouth` style models width, but from the
contact radius taken literally, which covers one hole and sometimes two. A real mouth covers
one to four. Whether `majorRadius` varies usefully on an iPhone has still not been measured;
that is what the drawn circle and the debug line are for. `UITouch.force` is not an option:
3D Touch hardware ended with the iPhone XS.

**No blend between neighbours.** A covered hole sounds at full volume and an uncovered one is
silent, with nothing in between. This is also why the horizontal crossfade is not physical: a
real slide overlaps, it does not fade.

**Blow and draw sound the same.** The library records 19 distinct pitches, not 20 reeds, so
nothing separates a blow reed from a draw reed. The screen still says which breath is
sounding; the ear cannot tell. An overblow is likewise just the pitch above, with none of the
strained timbre the technique has on the instrument.

**One key is recorded, the rest are stretched.** Every key but A is reached by resampling,
never more than a semitone, which is inaudible. A bend adds up to three semitones on top, and
that is audible.

**The licence has not been read.** The samples are a commercial library. Whether they may ship
inside an app is unsettled, which is why the folder is empty in git.

**An overbend cannot be pushed past its own pitch.** Players bend an overblow further up
after it pops. Here the axis stops at the overbend, so the travel above the threshold does
nothing. ROADMAP item 6.

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
| Whether the contact radius needs a multiplier to reach a mouth's one to four holes, and which | The measurement from a device |
| Whether vibrato rate becomes a third axis | Needs a free control |
