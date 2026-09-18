# Roadmap — the same instrument as a page

The app becomes a web page on GitHub Pages, playable in Safari on an iPhone, and the two share
the music rather than duplicating it. Current state and everything that already works are in
[AGENTS.md](AGENTS.md), including its own [Not built](AGENTS.md#not-built) list, which is about
the instrument and stays where it is.

Nothing here is scheduled. The order below is the order the work has to happen in, because each
step needs the one before it.

## Contents

1. [What transfers and what does not](#what-transfers-and-what-does-not)
2. [Settle this before any code](#settle-this-before-any-code)
3. [Layer by layer](#layer-by-layer)
4. [The shared score format](#the-shared-score-format)
5. [Where the files live](#where-the-files-live)
6. [What Safari on an iPhone cannot do](#what-safari-on-an-iphone-cannot-do)
7. [The steps](#the-steps)

## What transfers and what does not

**The Swift does not run in a browser.** `Domain/` is 1389 lines and imports only Foundation,
which is the cleanest it could be, and it is still Swift. Nothing about the layering changes
that.

**SwiftWasm was considered and is not worth it.** It would carry `Domain/` across and nothing
else: there is no AVFoundation and no CoreMotion in a browser, so `Audio/` and `Motion/` are
rewritten either way, and there is no SwiftUI, so `Features/` is rewritten either way. That
leaves a toolchain, a multi-megabyte download on a page that should open in a second, and a
bridge crossed on every touch event, to save the smallest layer.

**What transfers is the specification.** AGENTS.md says what every rule is and why, in numbers:
the bend range is the interval between a hole's two reeds minus one, an overbend is that
interval plus one, a reed speaks in 5 ms and stops in 20, the cup sweeps 2800 Hz to 600 Hz at a
resonance of four, vibrato is 1.5 per cent of the pitch and a quarter of the loudness wandering
by eight per cent and a fifth. A port that reads the same numbers off the same document is not
a rewrite from memory.

**And the tests transfer as names.** Every `test_subject_whenCondition_outcome` becomes the same
sentence in TypeScript asserting the same number. `B4 pulled three semitones is A♭4, 415.30 Hz`
is true in any language. That is the real return on having written them.

**The music transfers as data**, which is what the JSON below is for.

**The samples transfer as files**, which is the problem in the next section.

## Settle this before any code

**Publishing the samples on a public page is not the same question as bundling them in an app.**
A page serves the WAV files to everyone who opens it, in a form a visitor can save. That is
redistribution of a commercial sample library, and it is the one thing sample licences are
written to forbid. The licence is still unread, which was survivable while the folder was empty
in git and the files only ever reached one phone.

Four ways out, and the answer decides the whole audio plan:

| | What it costs |
|---|---|
| Record a harmonica ourselves | A harmonica, a microphone and an afternoon. 19 pitches, four seconds each. Ours to publish |
| Find a set under a licence that allows it | Searching, and probably worse recordings |
| Synthesise in the browser | No files at all, and the page loses everything phase 5 bought: the harmonics the cup needs, the timbre, the attack |
| Ship the page silent until the visitor supplies files | Honest, and nobody will do it |

The page is the reason this matters: if the answer is that the current library cannot be
published, the web version needs its own sound before it needs anything else.

## Layer by layer

| Swift | Becomes | Size | Notes |
|---|---|---|---|
| `Domain/Entities/Instrument` | TypeScript, plain values | 10 files | Straight port. Every number stays the number |
| `Domain/Entities/Playing` | TypeScript, plain values | 10 files | Straight port |
| `Domain/Entities/Scores` | TypeScript plus JSON | 8 files | The four tunes stop being code. `Fingerings` and `Playability` port as they are |
| `Domain/UseCases` | TypeScript | 2 files, 357 lines | `PlayHarmonica` and `PlayScore`. The only place with state |
| `Domain/Protocols` | TypeScript interfaces | 4 files | |
| `Audio/` | Web Audio, an `AudioWorkletProcessor` | Rewrite | The render loop is the same arithmetic; the plumbing is not |
| `Motion/` | `devicemotion`, behind a permission prompt | Rewrite | |
| `Features/Harmonica` | DOM, no framework | Rewrite | The view state and the presenter port; the views do not |
| `App/` | One entry point | Rewrite | |
| `Tests/` | The same names | Port | Nothing about what is asserted changes |

The presenter is worth saying twice: `HarmonicaPresenter` turns a `Harmonica` into strings and
flags, and that is language-independent work. Porting it keeps both platforms saying `overblow
↑` and `(D5 bend)` in the same places, which is the kind of thing that otherwise drifts in a
week.

## The shared score format

**JSON carries the music. It does not carry the playing.**

What goes in is exactly what `Score`, `ScoreEvent` and `ScoreNote` hold now: a name, the key the
music sounds in, the position it is played in, a tempo, and a list of events, each either a rest
of so many beats or a note with its holes, its breath, its length, and whatever the player does
to it — bent by so many semitones, arriving at so many, overbent, vibrato, slid from a hole,
shaken with a hole.

What stays in code, on both platforms, is every number about *how* a note is played: the 50 ms
articulation gap, the 40 ms slide step, the 60 ms shake and the 10 ms bend step, the crossfades,
the 5 ms a reed takes to speak, the cup and the vibrato. Those belong to the instrument and the
player, not to the piece. The project already draws this line and should keep drawing it: time
lives in the player.

That is also the practical argument. Put the playing in the file and every score carries a copy
of the instrument's behaviour, so improving the instrument means editing every piece, and the
two platforms drift through data rather than through code, which is far harder to see.

A note is written in **semitones**, not in axis travel, exactly as now. The reader asks the
tuning for the reed's range and divides, so a piece never has to know that hole 3 draw bends
three and hole 4 draw bends one.

**The text format stays, on the iOS side, as the thing a person writes.** `.score` files are
tabs with lengths and they are pleasant to type; JSON is not. `ScoreReader` keeps turning one
into a `Score`, and gains one more exit: writing that `Score` out as JSON. So there is one
format to share and one format to write, and the web only ever needs the first.

## Where the files live

```
Resources/
  Scores/       the four tunes as .json, committed
  Samples/      the WAVs, not committed, subject to the licence question above
Apps/iOS/       as now
Web/            the page, its TypeScript, its tests
```

The iOS target reads both out of `Resources/` instead of out of `Apps/iOS/`, which is two lines
in `project.yml` and one constant in `RecordedHarmonica`. `Apps/iOS/Scores/` keeps the text
scores a person writes, because those are theirs and are not shared.

Converting the four tunes from Swift to JSON is a real trade and worth naming: a typo in a tune
stops being a compile error and becomes a launch-time failure. It is still right, because the
alternative is the same four pieces written twice in two languages, and those will not stay the
same. `ScoreReader` already proves that reading a score at launch works.

## What Safari on an iPhone cannot do

None of these are reasons not to do it. They are the differences the page has to be designed
around rather than discover.

- **It cannot lock the orientation.** No page can. The best available is noticing portrait and
  asking the visitor to turn the phone.
- **Sound needs a tap first.** An `AudioContext` starts suspended and only resumes inside a
  gesture, so the page opens with something to press.
- **Tilt needs a tap and a prompt.** `DeviceMotionEvent.requestPermission()` must be called from
  a gesture and only works over HTTPS, which Pages is. Until it is granted, the cup stays open
  and the instrument is still complete.
- **The silent switch can mute it.** Web Audio on iOS goes through a channel the hardware switch
  can silence, which no permission fixes.
- **The contact width may not exist.** `Touch.radiusX` reads 1 where the hardware reports a
  point, and whether an iPhone reports more is exactly the measurement never taken natively
  either. So the page ships with one note per finger working for certain, and the two width
  styles appear only if the number moves.
- **Latency is worse.** A worklet on iOS runs at a few milliseconds' buffer, against
  `AVAudioEngine`'s better; playable, not identical.

## The steps

Each one ends somewhere that runs.

**0. Answers, not code.** Settle the licence. Put a throwaway page on Pages that prints
`touch.radiusX` and the tilt reading, and press it with a flat finger, a fingertip and two pads.
Both answers change what the later steps build.

**1. One copy of the music.** Create `Resources/`, move the samples folder, write the four tunes
as JSON, teach `Score` to read them, delete the four Swift files, point `project.yml` and
`RecordedHarmonica.folder` at the new place, and add the JSON exit to `ScoreReader`. Touches
`BundledScores`, `CompositionRoot`, `RecordedHarmonica`, `Score`, the four tune files,
`ScoreReader`, `project.yml`, and both READMEs. No test changes its expectation:
`WhatAScorePlaysTests` builds its own scores in code and `WhatAWrittenScoreBecomesTests` reads
from a string, so both are untouched. That is the evidence this step is a refactor and not a
behaviour change. The app stays green and identical.

**2. A page that draws the instrument.** `Web/`, TypeScript with no framework, a Pages workflow,
and the strip and the square drawn at the right proportions in landscape. No sound, no touches.

**3. The domain, test for test.** Port `Instrument`, `Playing`, `Scores` and the two use cases,
with the Swift test names carried across and the same numbers asserted. This is the step that
either proves the layering was worth it or shows where it leaked.

**4. Sound.** An `AudioWorkletProcessor` holding the voice bank: the sample read with linear
interpolation, the 5 ms attack against the change's own fall, the air spread across at most four
reeds, the bend as one multiplication, the vibrato and its wander, the cup as a state variable
filter. The offline render tests port too, because a worklet can be run offline the same way.

**5. Touches.** Pointer events into `PositionOnHarmonica`, the three playing styles, the square,
the note row, the plates. At the end of this step the page is an instrument.

**6. The tunes.** `PlayScore` driving the same instrument from the JSON, and the menu.

**7. Tilt.** The permission gate, the lean, the cup bar.

**8. The differences.** The portrait notice, the tap that starts the sound, and whatever step 0
said about the radius.

## Not in scope

Feature parity beyond the instrument: no `.score` text reader on the web, no offline install, no
saving anything. The page is the instrument and the four tunes, which is what the app is.
