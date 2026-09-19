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
12. [Not built](#not-built)

## Quick start

```sh
xcodegen generate          # after any change to project.yml
open MobileHarmonica.xcodeproj
```

Scheme `MobileHarmonica` builds the app and runs `MobileHarmonicaTests`.

`MobileHarmonica.xcodeproj` and `Apps/iOS/Info.plist` are generated and not committed. Neither
are the WAV files: `Resources/Samples/` ships empty and the app says sound is unavailable
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
Core/           HarmonicaCore, a SwiftPM package: the instrument itself, shared by
                every platform. Protocols, UseCases, and Entities split by subject:
                Instrument/ the harmonica, Playing/ what a finger does,
                Scores/ written music. Imports Foundation only
Resources/
  Samples/      the WAV files, shared with the web version, not committed
Apps/iOS/
  App/          entry point and composition root
  Audio/        AudioEngineProtocol implementation, reading out of Resources/Samples
  Motion/       TiltProtocol implementation, the device's lean read through CoreMotion
  Scores/       text scores the user writes, read at launch, not committed
  Features/     one folder per feature: view state, presenter, view model, views
  Logging/      TimestampedLog
  Navigation/   coordinator and routes
  Tests/        Harmonica/ for behaviour, Support/ for doubles and helpers
Web/            the same instrument as a page, in TypeScript. See Web/AGENTS.md
project.yml
AGENTS.md
ROADMAP.md
```

The app and the page are two implementations of one instrument, and what is shared between them
is in `Resources/`. Why each layer was rewritten rather than compiled across, and what is left to
share, is in [ROADMAP.md](ROADMAP.md).

The app target's sources are `Apps/iOS` with `Tests` excluded. The test bundle generates its
own Info.plist through `GENERATE_INFOPLIST_FILE`; without one Xcode refuses to sign it.

The instrument is a module and the app is not. Everything else is written as if it were one:
public on the boundary, imports pointing inward.

`Entities/` is sub-foldered because it passed twenty files, well past the fifteen where the
folder rules say sub-folders start. The split is by subject, not by role: the role is already
the folder above it.

**The screen is four views, not one.** `HarmonicaScreen` assembles and owns the lifecycle;
`KeyBar`, `HarmonicaStrip` and `ToneShapingZone` each draw one thing and keep their own touch
state, which is where it belongs since nothing outside them reads it. `FingerCircles` is
shared by the strip and the square. Only the pinch and the zone's size stay with the screen,
because the size is a frame the screen sets.

## Architecture

Clean layering. A rule lives in exactly one layer.

| Layer | Path | May import | Owns |
|---|---|---|---|
| Domain | `Core/` | Foundation | Entities, the protocols it needs, the use case |
| Audio | `Audio/` | AVFoundation, os | The synthesiser behind `AudioEngineProtocol` |
| Motion | `Motion/` | CoreMotion, UIKit | The lean behind `TiltProtocol` |
| Presentation | `Features/` | SwiftUI, UIKit, Combine | View state, presenter, view model, views |
| Composition | `App/` | everything | Building the graph |

**The domain is a package, not a folder.** `Core/` is `HarmonicaCore`, built by SwiftPM and
depended on by the app, so the compiler enforces the boundary that used to be a convention: the
app cannot reach past the package's public API, and the package cannot reach into the app at all.
Everything the app needs is `public`, including the memberwise initialisers, which a package has
to spell out.

The tests split the same way. What tests the instrument lives in the package and runs without an
app or a simulator; what tests the presenter, the oscillator or the screen stays in
`Apps/iOS/Tests`. The doubles they share, `RecordingAudioEngine` and `SilentLog`, are a second
product of the package, `HarmonicaCoreTestSupport`.

**The package's tests are compiled into the app's test bundle, not listed in the scheme.** A
SwiftPM test target has no host application, and Xcode refuses to run a tool-hosted bundle on a
phone: `Tool-hosted testing is unavailable on device destinations`. So `project.yml` gives
`MobileHarmonicaTests` a second source folder, `Core/Tests/HarmonicaCoreTests`, and the scheme
names that one bundle. The tests reach the package's internals through `@testable import`, which
the Debug configuration's testability already allows. `swift test` inside `Core/` still runs them
as the package's own target, on any machine with no simulator at all.

**Enforced boundaries.** Nothing under `Core/` or `Features/` imports AVFoundation or will
import AudioKit. No domain type imports `os`; it reaches the log through `LogProtocol`. Only
values cross a boundary.

**A view state names no domain type.** A presenter takes domain values and returns strings and
presentation values, and a view sees only the second kind, so the two layers change for their
own reasons. `PlayingStyle` has a presentation twin in `PlayingStyleChoice`, mapped out by the
presenter and back by the view model, and a breath reaches the plate as `LitHalf.top`. Both
used to travel as themselves, which let a view ask a domain value a business question and get
an answer the presenter had already given it a field for.

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

It picks **which harmonica is in your hands**, not what key you are playing in. A harmonica in
C played in second position sounds in G. `HarmonicaPosition` holds how far above the
instrument the music sits: none for first position, a fifth for second, a whole tone for
third. A `Score` names the key **the music sounds in** and the position it is played in, and
derives the harmonica it needs, so a blues in G written in second position calls for a
harmonica in C and moves the slider there when it starts.

`HarmonicaKey.sliderPosition` is where a key sits on the slider and has nothing to do with
`HarmonicaPosition`. The two were both called position until a score needed both at once.

## Interaction model

| Control | Input | Effect |
|---|---|---|
| Hole | Finger x on the strip, right of the square | Sounds that hole. How many fingers count, and how much one finger covers, is the playing style |
| Breath direction | y of the **topmost** finger | On or above the centre line blows, below draws |
| Breath intensity | \|y\| of the same finger | 0.2 on the line to 1.0 at the edge |
| Bend | Finger y below the middle of the square | 0 at the middle to the reed's full range at the bottom |
| Overbend | Finger y above the middle of the square | 0 at the middle to the reed's full shift at the top |
| Vibrato | Finger x in the square | 0 at the left to 51 cents at the right |
| Key | Slider in the top bar | Transposes every reed |
| Zone size | Pinch on the square | Resizes it, trading width with the strip |
| Hands | Leaning the phone to the right | Closes the cupped hands, from open at level to shut at 30 degrees |
| Playing style | Menu in the top bar | How many fingers count, and how many notes each one takes |

**Three playing styles, named after the two things that tell them apart**: how many fingers
count, and how many notes one finger takes. `severalFingersSeveralNotes` is the default, where
every finger takes part and each sounds every hole its contact circle overlaps, which is
`UITouch.majorRadius` either side of the centre. `severalFingersOneNote` keeps every finger but
gives each exactly the hole it is over. `oneFingerSeveralNotes` keeps the width and counts the
topmost finger only. Breath direction and intensity always come from the topmost contact's
centre, so an edge of a pad crossing the centre line changes nothing. Switching style silences
whatever was sounding.

The names are that long on purpose. They were `fingers` and `mouth`, then `notes`, `mouth` and
`solo`, and every one of those had to be explained again each time it came up, because a
metaphor for playing does not say which of the two questions it is answering. `PlayingStyle`
answers them separately, as `coversTheContactWidth` and `takesTheTopmostFingerOnly`, so no case
ever has to be decoded. The fourth combination, one finger and one note, is an instrument that
plays no chords, so it is not offered.

The control is a menu rather than a segmented control, because the whole point is that the
names are sentences and a segment is too narrow for one. The button shows the name of the style
that is on, word for word as the menu lists it: a button that abbreviated what the menu spelled
out gave the same style two names and left the reader matching them up.

The radius is taken literally, with no multiplier, and it is deliberately on trial: at the
natural square size a hole is about 66 points and a fingertip reports something like 8 to 30,
so a contact covers well under one hole and reaches two only by straddling a boundary. Two
things measure it. The finger circle is drawn at the reported radius wherever width counts
instead of the fixed 56 points, and `PlayHarmonica` logs the width in hole widths at debug
level, deduplicated to a hundredth. Decide the multiplier from those numbers, not from an
estimate.

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
hole in one breath direction exactly one half is live, so the other half's label dims. The live
label names the technique this reed actually offers, `overblow ↑` on holes 1 to 6 and
`overdraw ↑` on 7 to 10, which the breath alone decides; with nothing sounding there is no reed
to name and it reads `overbend ↑`.

The two halves are not one control split in two, and the dim half is not wasted travel. The
mouth tunes its own resonance, and a bend is that resonance taken **below** the sounding reed,
with the tongue root up and the larynx down; an overbend is the same resonance taken **above**
it, tongue and larynx forward and high. They are opposite adjustments on one continuum, so an
axis with rest in the middle is the shape of the thing itself. The dim half is a real mouth
position that does nothing on this chamber, exactly as on the instrument, and the live half
changing when the breath turns is the instrument too: hole 1 bends drawn and overblows blown,
and the player's mouth really does go the other way.

The axis is read against the reed sounding now, not against an absolute mouth shape. A blow
bend on holes 8 to 10 is made high and forward while a draw bend on 1 to 6 is made low and
back, because the resonance has to sit just under whatever pitch is sounding. Relative to that
pitch both are the same move, which is why one rule covers the whole instrument instead of a
table. Each
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
does nothing, and that is where the stretch would go. See [Not built](#not-built).

An overbend shifts every sounding reed at once, each by its own range, which is not the rule
the bend follows. A bend is one vocal tract pulling on whatever is under it, so every reed
moves together and the shallowest chamber sets the limit. An overbend is a reed changing which
mode it sounds in, so each chamber lands where its own two reeds put it. One mouth cannot
overblow a chord on the instrument anyway.

**The demo plays itself through the instrument, not around it.** `PlayScore` names holes and a
breath and puts them through `PlayHarmonica.play(_:breathing:)`. Nothing about the tuning, the
bend ranges or the crossfade is written a second time, and everything the screen already shows
keeps working: the plates light, the note row names the note, a bend is a fraction of that
reed's own range.

What a score does not go through is the finger interpretation, because there is nothing to
interpret: it already says which holes. It used to build synthetic finger positions and go
through `play(at:)`, and then the playing style reinterpreted the music — with one finger
counting, a written
three-hole chord came out as whichever single hole the arbitration picked. The switch describes
how to read a live hand, so `play(at:)` is where it lives and the score enters beside it.

**An event names holes, not a hole**, because a mouth covers two to four of them and that is
how the instrument is actually played: the chords are the rhythm and the single notes are the
melody, in the same phrase. They all sound on the breath the event names, at full pressure,
because one mouth gives one airflow.

**A slide is a run of holes, not a pitch glide.** A mouth dragging across the strip sounds
every hole it passes, so `ScoreNote.slideFrom` names where the slide starts and `PlayScore`
expands it into those holes, each about 40 ms, taking its time from the front of the note it
arrives at. The engine is not told: a slide is several changes over time, and time lives in
the player.

It is a hole rather than a flag because a flag cannot say where to start. A slide on the
first note of a piece, or between two notes on the same hole, would have nowhere to come from
and would quietly do nothing.

**A shake and a released bend are one note that changes while it lasts.** `shakenWith` names
the hole the mouth rocks to and back, and `bendEndsAtSemitones` where the bend arrives by the
end, so a scoop is a note that starts bent and lands plain. Either one makes `PlayScore` step
through the note in 60 ms slices instead of sounding it once, setting the shaping and the
holes at each slice; a note with neither is still one call.

A shake is not a slide. A slide is a transition, passing each hole once in one direction and
consuming the front of the note it arrives at. A shake is an ornament that rocks between two
holes for the whole note and arrives nowhere. Written as a chain of slides it would be
sixteen events, each re-attacking and each cut short for articulation, which is a burst of
staccato rather than a warble.

**How a written note is timed lives in `ScoreTiming`**, which the package exports: how much of a
note is given up so the next one re-attacks, how long a slide rests on each hole it passes, how
fast a shake rocks and how finely a bend envelope steps. Those four numbers are music rather than
platform, and the page has its own player because the core has no executor to sleep on, so it
asks the core for them at startup through the same door it already asks for the reed ranges.
They were written out twice until then.

A score says a bend in **semitones**, not in axis travel, because a score should not know that
hole 3 draw bends three semitones and hole 4 draw bends one. `PlayScore` asks `RichterTuning`
for the range and divides. Each note is cut short by up to 50 ms so the next one re-attacks;
without that gap two of the same note in a row would be one long note, because the instrument
sees the same reeds and does not re-sound. A rest is then only time: every note already ends
silent, so a rest has nothing left to stop.

**A note that changes while it sounds is stepped, and the step is not one length.** A shake
re-sounds reeds, so it rocks at 60 ms, which is about as fast as a mouth moves. A bend envelope
is one number the render thread reads, so it steps at 10 ms. Both were 60 ms, and on a fast
tune a three-semitone release arrived in six jumps of 60 cents, which is a staircase rather
than a bend; at 10 ms the same release steps by under eight cents.

Each step waits for its own share of the note counted from where the note began, not for a
slice at a time. Sleeping slice by slice adds every sleep's overshoot to the note, so the finer
the stepping the longer the note grows, and a forty step note would drift out of the bar.

**A score can be written instead of coded.** `Apps/iOS/Scores/*.score` is a text file with a
key, a position, a tempo and lines of pitches with lengths in beats; `ScoreReader` turns it
into a `Score` and the demo button plays the first one it finds. The files are not committed,
the same as the WAV samples, because what a person writes there is theirs. The format is in
that folder's README.

The interesting half is `Fingerings`, which answers what a written pitch costs on the
harmonica in a given key: a plain note, a bend of so many semitones, or an overbend. The
reader prefers plain to bent and bent to overbent, and among equal choices takes the hole
nearest the one before, so the mouth moves as little as it can. A chord takes its breath from
its lowest pitch and the rest must be reachable on that breath, because one mouth gives one
airflow.

`Playability` is what it reports: how many bends and overbends the piece needed, the widest
leap in holes, and every pitch this harmonica cannot reach in this key. It goes to the log at
launch. A leap past three or four holes is one no mouth makes at speed, and that is the
honest answer to whether a given piece suits the instrument at all.

**`Score.tunes` is four pieces, and the play button is a menu over them**, with any bundled
`.score` file first. All four are **settings written out of the idiom**, not transcriptions of
anyone's recording or published tab, and each exists to put one group of techniques on the
instrument at once:

| Tune | What it is for |
|---|---|
| Blues strain | Twelve bars in G, second position: train chug, the I, IV and V chords, the bent third draw, a shake in the upper fill, the hole 6 overblow |
| Slow drag | Scoops and released bends, long notes under vibrato, a slide into a phrase, one shake |
| Hammer song | Chugging blow and draw, tongue-block octaves on holes 1 and 4, tongue slaps, syncopation |
| Fox chase | A gallop chug, shakes, deep bends released, horn chords. Its bars are deliberately uneven, as the genre is |
| Nese Halia vodu | Ukrainian folk, in A, third position on a harmonica in G |
| Oi pid vyshneiu | Ukrainian folk, in D, third position on a harmonica in C |
| Na Ivana na Kupala | Ukrainian folk, in G, first position on a harmonica in G |

Octaves and tongue slaps needed no new code: an event already names a set of holes, so an
octave is `[.one, .four]` and a slap is a chord of 0.15 beats followed by the single note.

**The three Ukrainian ones are melodies rather than settings**, and they are there to be played
along with rather than listened to: single notes, no bends, no overbends, all inside holes 4 to
6, so every one of them can be taken with a mouth. Their keys and positions were chosen to make
that true, which is why two of them ask for a harmonica in G and one for a C.

They are folk songs with no author, and no edition was transcribed: the melodies are written as
they are commonly sung. That means a wrong interval is possible and is meant to be corrected by
ear, in the file, the same way the other four were shaped.

A live finger stops the score, since both drive one instrument, and **a stopped score then
touches nothing**: it does not end its note, rest the shaping axis or ring the reeds down,
because by then the finger is playing and those are its reeds now. The tail used to run whatever
stopped the score, so taking over from the demo silenced the very note the finger had just
sounded, up to a note's length later. Whoever stops the score decides what follows: the stop
button silences, a finger plays on. Timing is `Task.sleep`, whose jitter is a few milliseconds:
fine for a demo, not for music. See [Not built](#not-built).

**A sounding plate lights only the half that is sounding**, the top for blow and the bottom
for draw, so the demo shows where to put a finger and which way to breathe. It used to light
both halves, which said which hole and not which breath. Which half a breath lights is the
presenter's decision, so `HoleViewState` says `top` or `bottom` and the view never hears the
word blow.

**One breath for the whole instrument.** One mouth gives one airflow, so the topmost finger
decides direction and intensity for every sounding hole. The boundary belongs to blow.

**The boundary has slack, and nothing changes while a finger is in it.** Within six per cent of
the strip's height either side of the centre line, the instrument holds whatever it is already
sounding: not the breath, not the hole, not the intensity. Leaving the slack applies both the
breath and the hole at once.

Without it, moving from hole 2 drawn to hole 3 blown was impossible rather than awkward. The
finger has to cross the line and a hole boundary, and whichever it crosses first sounds a note
nobody asked for: hole 2 blown, or hole 3 drawn. There is no path that avoids one, because both
axes were read on every touch. With the slack the crossing happens inside it and the next thing
heard is the note that was aimed at.

It costs nothing that was there before. A chug still works, because a finger crossing the line
without moving sideways leaves the slack on the same hole. A slide still works, because a finger
running along the strip well away from the line never enters it. And a finger resting near the
line stops flickering the note, which is the same reason the shaping axis has a deadband around
rest.

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

**The top bar stands clear of the screen's edge.** A tap or a drag that starts in the first few
points below the top belongs to the system, which reads it as a pull for Notification Centre, so
the bar keeps 20 points of nothing above it and its controls are 40 points tall rather than the
28 a bordered menu takes. The middle of a control, which is what a thumb aims at, then sits
around 40 points down instead of 22. The bar grows by those 20 points and the strip gives them
up, which changes no hole's width.

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
| `soundTones(_:as:)` | On reed change | Fades the voices that are no longer wanted, starts the new ones from their attack |
| `changeIntensity(to:)` | Every touch move | One number in its own lock |
| `changeBend(to:)` | Every touch move | One number in its own lock |
| `changeVibrato(to:)` | Every touch move | One number in its own lock |
| `cupHands(to:)` | Every lean of the phone | One number in its own lock |
| `silence(_:)` | Lift, or a note ending | Rings every voice down, or damps it, depending on which stopped it |

**Why the split.** Continuous parameters change on every touch event while the set of
pitches changes rarely. Routing them through the voice bank would rewrite the voice array on
nearly every buffer for a number that is one `Double` wide.

**A reed speaks fast and dies at the pace of the change.** The rise is 5 ms whatever else is
happening, because that is how long a reed takes to speak and the recording already carries its
own attack; fading it in over the whole crossfade blunted every articulation. The fall is the
crossfade the caller named: `.slide` is 20 ms, enough to remove the click at a hole boundary and
short enough that a fast run is not smeared, and `.newReed` is 50 ms, for an overbend engaging
or releasing, where one reed really does hand over to another. The domain names the event and
the audio layer owns the milliseconds.

**Letting go and being stopped are two different things**, and `ReedRelease` says which one
happened. When the mouth comes off there is nothing to damp the reed, so it rings down on its
own, exponentially, over about thirty cycles of its own pitch: 29 ms at C6, 68 ms at A4, 115 ms
at C4. Measurements of a harmonica reed give 30 to 60 ms up high and 150 to 200 ms down low,
which is the same statement said the other way round, because the damping is viscous and a
reed's velocity scales with its frequency, so what is constant is the count of cycles rather
than the time. Thirty rather than the forty-five those figures average to, because a well set up
instrument with tight slots and no leaks damps harder, and a set up instrument is what this
project models everywhere else.

When something stops the reed instead, it is damped and gone in 20 ms, linearly. That is the
tongue between two notes of a chug, the mouth sliding to the next hole, and the air reversing. A
score articulates, a lifted finger releases.

Both used to be one linear 20 ms borrowed from whatever `crossfadeSeconds` last held, so nothing
ever rang, a released note ended like a fade rather than like an instrument, and a note released
after an overbend took 50 ms while the same note after a slide took 20.

Rise and fall being different is what makes a slide physical: the arriving hole is at full
volume 5 ms in while the leaving one is still dying, so both sound together for a moment, which
is what a mouth dragging against the strip actually does. It used to be a true crossfade, one
reed's gain trading against the other's, which is a dissolve and not a mouth.

**A reed that has stopped speaks again rather than resuming.** A voice that is still wanted
keeps sounding, because the mouth never left that hole. A voice that is fading is never revived:
when its pitch is asked for again, it goes on dying and a new voice starts from the recorded
attack beside it. Reviving it meant a note taken again within the fade came back from the middle
of its loop with no attack at all, which is what made a fast repeat on one hole sound smeared.

**Turning the breath makes every reed speak again**, because every reed really does stop when
the air reverses. `ToneChange.breathReversed` says so, and the bank drops all its voices and
starts the wanted pitches afresh. Without it a pitch belonging to both breaths carried straight
through the reversal: on a C harmonica that is G4, hole 3 blown and hole 2 drawn, so a contact
covering both holes kept one note going while the rest re-attacked.

**The recordings.** `RecordedHarmonica` reads every WAV in the bundle's `Samples` folder at
`prepare()`, mixes each to mono and appends it to one contiguous `[Float]`, so nothing is
streamed or decoded while the audio runs. A `RecordedNote` says where its frames start and
where its loop is; all of it is trivially copyable, so a voice carries one by value and the
render thread never retains anything.

`SampleBank.nearest(to:)` picks the recording closest in pitch, measured in octaves rather
than hertz, and the voice reads it at `wanted ÷ recorded` times speed. The library is one
harmonica in A, and inside its own range, A3 to A6, its scale leaves every chromatic pitch
within a semitone of some recording. Stretching moves the formants with the pitch, which is
what a real bent reed does anyway. Above A6 it has nothing, and that is where the stretch grows:
see [Known limits](#known-limits).

The library labels its files an octave below concert pitch, which is what
`semitonesAboveTheLabel` adds back. Nothing has confirmed it. If it is wrong every note is an
octave out, and the note row is the check: hole 4 blown on a C harmonica says C5, and the ear
either agrees or the constant goes.

**The loop is seconds 1 to 4 of each file**, chosen rather than read from the library's EXS
mapping, and frames past second 4 are never loaded. The files themselves are cut to those four
seconds, because what is never loaded was still being carried to the phone and to the page: the
library's takes ran from 4.4 to 12.7 seconds and cost 18.9 MB, where the four seconds that are
read cost 10.1. Nothing is re-encoded, so they are still 24-bit mono at 44.1 kHz. A note plays from frame 0, so it keeps its
recorded attack, then repeats that window for as long as the finger is down. A file too short
to hold the window throws and names itself.

**The loop's tail is blended into its own approach when the file is read**, 150 ms of equal
power, so that the last frame of the loop is the frame that precedes its start and the wrap is
an ordinary step in the waveform. Without it the loop jumped by up to 1.15 of full scale on the
19 recordings here, where an ordinary step between two frames inside a note never passes 0.32:
that jump is the click. A reed also decays across three seconds, so the wrap stepped the level
by up to 2.3 dB, and the blend turns that step into a glide over the same 150 ms.

150 ms is 16 periods of the lowest recording, A2 at 110 Hz, which is enough that the two copies
do not comb, and 5 per cent of the loop, which is little enough that whatever expression the
recording holds there is not averaged away. Measured across the library, a longer fade does not
cancel less: the interference between two moments of one steady note is about 2 dB whatever the
length, so the length is chosen for how long that colouring lasts, not for how deep it is.

The blend happens once, when the file is read, so the render thread is untouched: it still wraps
by moving an index.

**Mixing.** One mouth gives one breath, and up to about four chambers it is enough for all of
them: the voices are summed and scaled only by the breath gain, so a chord really is louder
than one note, by the square root of the reeds sounding. Past four the sum is divided down, so
a hand covering all ten holes is held at the loudness of four.

That bound is what keeps it from clipping. Four reeds at full scale and perfectly in phase
reach 4, the output amplitude is 0.25, and the product is exactly full scale; real recordings
peak below full scale and different pitches never align, so the headroom is never spent.

It used to divide by the total gain instead, so a chord of three sounded each note at a third
and the whole chord no louder than one note. Every tune here is built on chords, and they all
sounded far away.

**Bend** is one multiplication by `2^(-semitones/12)`, applied per voice once per buffer.
Cheaper than a sample, which has to be dragged off its recorded pitch.

**One mouth pulls every sounding reed by the same amount**, and the shallowest chamber decides
how far, because that is the one that runs out first. `PlayHarmonica` takes the smallest bend
range among the sounding reeds and gives it to every tone, so a chord bends as a chord. Before
this each reed bent by its own range, and holes 3 and 4 drawn together at full bend turned a
minor third into a fourth.

**The overbend is not a parameter.** It changes which reed sounds, so it goes through
`soundTones` as a different pitch and crossfades, the same event as moving to another hole.
The engine never hears the word: the domain computes the overbent pitch and sends it as a tone
with no bend range, because an overblow cannot then be bent down.

It was a parameter first, a ratio stepped from 1 to `2^(semitones/12)` on one voice. That is
a pitch teleport with no amplitude transition, more abrupt than anything the instrument does.
Removing `smooth` is what made the better shape available: with only a threshold left, the
overbend engages rarely rather than on every touch move, so it belongs with the rare calls.

**Cupped hands are one low pass on the mix.** Hands closed around a harmonica are a cavity that
eats the high partials, so closing them darkens the note rather than changing its pitch. One
pole is enough for that, and it costs one multiply and one add per sample: the cutoff sweeps
exponentially from 20 kHz open, where nothing is audibly touched, down to 800 Hz shut, which
keeps every fundamental on the instrument and takes the harmonics off. The coefficient is worked
out once a buffer, so nothing transcendental runs per sample.

A resonant version was built and taken out. A real cup rings as well as closing, and sweeping
that resonance down is what makes a wah a vowel rather than a tone control, which is why it
looked like the better model. On this instrument it sounded worse: normalising the peak by the
resonance meant closing the hands mostly dropped the level, so a wah came out as the harmonica
going quiet and boxy instead of speaking. The lid is what the instrument has until something
fixes that.

High notes are muffled harder than low ones, which is not a bug to fix: a real cup is a fixed
size, so what it takes off a note depends on where that note's partials sit.

The phone's lean is what a mouth cannot give. Cupping is a whole-instrument gesture and both
hands are already on the glass, so it costs no screen space. `DeviceTilt` reads the gravity
along the device's long axis, which is zero when the phone is level in landscape and reaches a
half at thirty degrees, and flips its sign with the interface orientation so that leaning the
screen's right edge down always closes. There is a slack of three degrees around level, because
gravity is never exactly zero in a hand.

**Vibrato** is one shared LFO near 5.5 Hz, and it moves two things: the pitch by 1.5 per cent,
about 26 cents, and the loudness by up to a quarter. A harmonica's vibrato is mostly the
loudness pulsing; 51 cents of pitch and nothing else read as a siren rather than a note being
played. The loudness only dips, never rises, so vibrato cannot spend the headroom the mixing
leaves.

**Its rate and depth wander**, because nobody holds 5.5 Hz. A second wave at 0.23 Hz moves the
rate by eight per cent and the depth by a fifth, and it moves them against each other: faster
is shallower, slower is deeper, which is how a vibrato breathes rather than how a machine
repeats. It is a wave and not a random number, so the same phrase played twice sounds the same
twice; a player whose vibrato wandered unpredictably would not be a player in control. It is
worked out once a buffer, since 0.23 Hz moves by less than a per cent inside 20 ms.

## Concurrency contract

**The oscillator** is reached from the render thread and the main thread. All state sits
behind `OSAllocatedUnfairLock`. The render thread reads the bank, renders a whole buffer
outside the lock, then takes the lock again and **merges its progress into whatever the bank
now holds**: phase, gain, breath gain and LFO phase per voice, matched by the number the voice
was given when it started. A voice the render pass did not hold was either added mid-buffer or
finished fading out, and both start a cycle at phase zero.

The number is what lets two voices hold one pitch, which is what a note taken again before it
has faded needs: the old one goes on dying while the new one speaks. Matching by frequency was
enough only while a pitch could never appear twice, and buying that uniqueness cost every
re-articulation.

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

**Publishing.** `HarmonicaViewModel` is `@MainActor`, and so is every view that speaks to it,
so the compiler checks which thread publishes instead of a convention nobody can enforce. It
costs nothing at run time: those calls all came from the main thread already, and the
annotation only lets the compiler prove it. Before this, every `async` function that ended by
publishing had to be marked by hand, and the rule held only as long as the next person read it.

Three seams had to say it out loud. `HarmonicaScreen.init` takes a `@MainActor` autoclosure and
opens it with `MainActor.assumeIsolated` inside the one `@StateObject` takes, so the view model
is still built lazily and now provably on the main actor. `TouchArea` declares both of its
callbacks `@MainActor`, which is what `UIView` already is, so a touch reaches the view model
with no hop. `CompositionRoot.harmonicaScreen()` is `@MainActor` because it builds one.

What must stay off the main actor is preparing the sound. `PlayHarmonica.prepare()` is not
isolated, so its body runs on the cooperative pool and the audio session is configured in a
detached task inside that; awaiting it from `prepareSound()` suspends the main actor rather
than blocking it. `AppCoordinator` stays a plain `ObservableObject`, because nothing reaches it
from anywhere but a view.

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

A score test runs at 6000 beats a minute so it finishes in no time, but a note that changes
while it sounds needs a real tempo: at 10 ms a beat there is nothing to step through, and a
shake or a released bend collapses to one slice that proves nothing.

Sound is the one guarantee no screen can show, so it is checked where it is visible: on the
real `Oscillator`, rendered offline into an `AudioBufferList` by `RenderedSound`, with pitch
read back from rising zero crossings. Thresholds are chosen so the reader can do the
arithmetic: 440 Hz swung by 1.5 per cent covers 13 Hz, so a spread over 5 Hz is vibrato and
under 2 Hz is the estimator wandering; B4 pulled three semitones is A♭4, 415.30 Hz.

Everything else drives the app's own graph with the leaves swapped.

**Where a rule exists on both platforms, both sides test it.** The page had tests for reading a
recording and the phone had none, although both readers follow the same rules, so
`WhatTheRecordingsAreReadTests` now says the same things on this side. What the instrument itself
promises is tested once, in the package, because the page runs that same code as WebAssembly and
a second copy of those tests would only prove the two builds agree with each other. And because
the audio layer is written twice on purpose, a test on the page reads both trees and fails if a
constant of the same name has drifted apart: 21 of them are written twice today.

## Known limits

**Mouth width is only as wide as a fingertip.** Both several-note styles model width, but from the
contact radius taken literally, which covers one hole and sometimes two. A real mouth covers
one to four. Whether `majorRadius` varies usefully on an iPhone has still not been measured;
that is what the drawn circle and the debug line are for. `UITouch.force` is not an option:
3D Touch hardware ended with the iPhone XS.

**No blend between neighbours.** A covered hole sounds at full volume and an uncovered one is
silent, with nothing in between. The slide across a boundary does overlap now, since a reed
rises faster than the one it replaces falls, but how much of a hole is covered still changes
nothing.

**Blow and draw sound the same.** The library records 19 distinct pitches, not 20 reeds, so
nothing separates a blow reed from a draw reed. The screen still says which breath is
sounding; the ear cannot tell. An overblow is likewise just the pitch above, with none of the
strained timbre the technique has on the instrument.

**One key is recorded, and the top of the range runs out.** Every key but A is reached by
resampling. From A♭ to B♭ nothing is stretched more than a semitone, which is inaudible. Above
that the top reeds pass the library's highest recording, A6, and the stretch grows with the
key: three semitones on hole 10 in C, five in D, nine in F♯. A bend adds up to three semitones
on top of whatever the key already asks for.

**The licence has not been read.** The samples are a commercial library. Whether they may ship
inside an app is unsettled, which is why the folder is empty in git.

**An overbend cannot be pushed past its own pitch.** Players bend an overblow further up
after it pops. Here the axis stops at the overbend, so the travel above the threshold does
nothing. See [Not built](#not-built).

**The wah has no resonant peak.** A real cup is a resonator as well as a lid, so it lifts a
band as it closes rather than only taking the top off. One pole cannot do that. A biquad can,
at the price of recomputing coefficients once a buffer; worth it only if the one pole sounds
like a tone control rather than like hands.

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
| Whether the contact radius needs a multiplier to reach a mouth's one to four holes, and which | The measurement from a device |
| Whether vibrato rate becomes a third axis | Needs a free control |

## Not built

Nothing here is scheduled, and none of it is in the way. What each one waits on is the point.

| | Waits on |
|---|---|
| **Layers by breath pressure.** Intensity is gain alone, so blowing harder is louder and never dirtier | Nothing. The library ships a velocity switched set beside the plain one, and only the plain one has been copied in |
| **A recorded vibrato instead of the LFO.** Crossfading a vibrato set against the plain one by depth is a real vibrato rather than a modulated one, at twice the memory | Nothing. The library ships that set too |
| **A timbre per reed.** 19 recorded pitches cover 20 reeds, so blow and draw sound alike | A library sampled per reed. Nothing else can fix it |
| **A mouth's worth of width.** The contact radius is spent literally and covers about one hole, where a mouth covers up to four | One measurement on a device. The circle is drawn at the reported radius and the width is logged at debug level; press flat, on the tip, and with two pads, and see whether the number moves |
| **Guide mode.** The next hole lights and waits to be taken, so the rhythm comes from the player rather than the clock | Nothing but the work |
| **A score that cannot be played is not refused.** `Playability` reports the leaps and the unreachable pitches; nothing acts on the report | A decision about what refusing should do |
| **The clock.** Notes are placed with `Task.sleep`, which drifts a few milliseconds. Inside a note the stepping already counts from the note's start, so only note to note drifts | Wanting music rather than a demo. The fix is the audio clock |
| **An overbend pushed past its own pitch.** Players bend an overblow further up once it pops; here the axis stops at the pop and the travel above the threshold does nothing | Deciding it is worth the engine contract. The pop is an additive shift that differs per reed, while the axis fraction is shared, so one multiplication per voice stops being enough |
| **A cup that rings as well as closes.** A real cup lifts a band as it shuts and slides it down, which is what makes a wah a vowel. Built once as a state variable filter and taken out again: normalising its peak turned closing the hands into a drop in level rather than a vowel | Working out how to keep the peak without losing the level, and hearing that it beats the plain lid |
| **Vibrato rate as a control.** Slow and wide against fast and narrow are different sounds, and the rate only wanders on its own | A free control. Leaning the phone left is the one place left: it is clamped to nothing today |
| **Remembering the pinched square.** It returns to its natural side on every launch | Storage, which the project has none of |

**Decided against, so it is not rediscovered as a bug.** Equal loudness compensation: drawn notes
on holes 1 to 3 sound 1 to 1.6 dB louder than blown ones at the same amplitude, because the ear
hears the higher note as louder. A real harmonica does this too, and it is why blues lives on
the draw notes.

**A missed overblow is not modelled either.** On a factory instrument it chokes or squeals, and
it takes a set up harmonica with its gaps adjusted to pop cleanly every time. So the clean
threshold is not a simplification, it is which instrument this is: the one a player who wants
to play fast would own. Modelling the squeal would also have to live exactly where the deadband
around rest is, and would bring back the flicker the deadband exists to stop.
