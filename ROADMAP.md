# Roadmap — the same instrument as a page

The app becomes a web page, playable in Safari on an iPhone, and the two platforms share what is
genuinely shared instead of keeping two copies of it. Current state and everything that already
works are in [AGENTS.md](AGENTS.md), including its own [Not built](AGENTS.md#not-built) list,
which is about the instrument and stays where it is.

Nothing here is scheduled. The order below is the order the work has to happen in, because each
step needs the one before it.

## Contents

1. [What is shared](#what-is-shared)
2. [Where the files live](#where-the-files-live)
3. [Layer by layer](#layer-by-layer)
4. [The page in Safari](#the-page-in-safari)
5. [The steps](#the-steps)
6. [Not in scope](#not-in-scope)

## What is shared

**The music is data and belongs in one file per piece.** The four tunes are Swift today, which
means porting them would mean writing each one twice in two languages and watching them drift.
They become JSON, and each platform maps that JSON into its own model. A piece is written once
and played by both.

**The rules are code, and the code is the specification.** `Domain/` says what a bend range is,
what an overbend shifts by, how far a mouth can pull a chord, in the only form that cannot be
vague: 1389 lines that already run and are already tested. The port is written by reading those
files, not by remembering them. AGENTS is the history behind them — why each number is that
number and what was tried before — and the tests are what must still be true afterwards. Code
first, tests second, AGENTS for the reasons.

**The samples are files and belong in one folder.** Both platforms load them the same way from
the same place. They are not committed, exactly as now.

## Where the files live

```
Resources/
  Scores/       one .json per tune, committed
  Samples/      the WAVs, not committed, dropped in by hand as now
  index.json    what is in the two folders
Apps/iOS/       the app, reading out of Resources/
  Scores/       the .score text files a person writes, theirs, not shared
Web/            the page, its TypeScript, its tests
```

**Why an index file.** iOS finds the samples with `Bundle.main.urls(forResourcesWithExtension:)`,
which enumerates a directory. A browser cannot enumerate anything: it can only fetch a name it
already knows. So the folder carries a small index of what is in it, and both platforms read
that instead of one enumerating and the other guessing. One mechanism rather than two, which is
the point of the shared folder.

**The text score format stays on the iOS side**, because `.score` files are tabs a person types
and JSON is not pleasant to type. `ScoreReader` keeps turning one into a `Score` and gains one
more exit: writing that `Score` out as JSON, so something typed as a tab can be shared.

**What JSON holds and what it does not.** It holds the music: a name, the key the music sounds
in, the position it is played in, a tempo, and a list of events, each a rest of so many beats or
a note with its holes, its breath, its length, and what the player does to it — bent by so many
semitones, arriving at so many, overbent, vibrato, slid from a hole, shaken with a hole. That is
exactly what `Score`, `ScoreEvent` and `ScoreNote` hold now.

It does not hold how any of that is played: the 50 ms articulation gap, the 40 ms slide step, the
60 ms shake and 10 ms bend step, the crossfades, the 5 ms a reed takes to speak, the 30 cycles it
rings down over, the cup and the vibrato. Those belong to the instrument and the player, and the
project already draws that line: time lives in the player. Put them in the file and every piece
carries a copy of the instrument's behaviour, so improving the instrument means editing every
piece, and the two platforms drift through data rather than through code, which is far harder to
see.

A bend is written in **semitones**, not in axis travel, exactly as now, so a piece never has to
know that hole 3 draw bends three and hole 4 draw bends one.

## Layer by layer

| Swift | Becomes | Size | Notes |
|---|---|---|---|
| `Domain/Entities/Instrument` | TypeScript, plain values | 10 files | Read and rewritten line for line. Every number stays the number |
| `Domain/Entities/Playing` | TypeScript, plain values | 10 files | Same |
| `Domain/Entities/Scores` | TypeScript plus the JSON | 8 files | The four tunes stop being code. `Fingerings` and `Playability` port as they are |
| `Domain/UseCases` | TypeScript | 2 files, 357 lines | `PlayHarmonica` and `PlayScore`. The only place with state |
| `Domain/Protocols` | TypeScript interfaces | 4 files | |
| `Audio/` | Web Audio, an `AudioWorkletProcessor` | Rewrite | The render arithmetic is the same; the plumbing is not |
| `Motion/` | `devicemotion`, behind its permission prompt | Rewrite | |
| `Features/Harmonica` | DOM, no framework | Rewrite of the views; the view state and the presenter port | Keeping the presenter is what keeps both platforms saying `overblow ↑` and `(D5 bend)` in the same places |
| `App/` | One entry point | Rewrite | |
| `Tests/` | The same names, the same numbers | Port | `B4 pulled three semitones is A♭4, 415.30 Hz` is true in any language |

The offline render tests port too: an `AudioWorkletProcessor` can be driven a buffer at a time
outside a page, the same way `RenderedSound` drives the oscillator outside an app.

## The page in Safari

**The interface fills exactly what is visible, in either landscape.** The orientation cannot be
locked by any page, but the phone still turns, and when it does the instrument has to occupy the
visible area one to one: no scrolling, no rubber banding, no toolbar eating the bottom of the
strip, no gap where the notch is. That means `dvh` rather than `vh`, the visual viewport rather
than the layout viewport, `env(safe-area-inset-*)` doing what `safeAreaPadding` does on iOS, and
a relayout on both `resize` and `orientationchange`. In portrait the page says to turn the phone,
because a ten hole strip across a portrait screen is not an instrument.

**Sound starts on a tap.** An `AudioContext` begins suspended and resumes only inside a gesture,
so the page opens with something to press. The same tap can ask for motion.

**Tilt needs a prompt.** `DeviceMotionEvent.requestPermission()` must be called from a gesture and
only over HTTPS. Until it is granted the cup stays open and the instrument is complete without it.

**The contact width is a measurement, not a search.** `Touch.radiusX` exists in the standard but
is not Baseline, and where the hardware reports a point it reads 1. Whether an iPhone reports
more is exactly the question never answered natively either, where `UITouch.majorRadius` has been
logged and never read. One page that prints the number answers it for both. Until then the page
ships with one note per finger, which needs no width at all, and the two width styles arrive when
the number does.

## The steps

Each one ends somewhere that runs.

**0. One measurement.** A throwaway page that prints `touch.radiusX`, `radiusY` and the tilt
reading. Press it flat, on the tip, and with two pads. This answers the width question for the
app as well.

**1. One copy of the music.** Create `Resources/`, move `Samples/` into it, write the four tunes
as JSON, write the index, teach `Score` to read a tune from JSON, delete the four Swift tune
files, point `project.yml` and `RecordedHarmonica` at the new folder, and add the JSON exit to
`ScoreReader`. Touches `BundledScores`, `CompositionRoot`, `RecordedHarmonica`, `Score`,
`BluesStrain`, `SlowDrag`, `HammerSong`, `FoxChase`, `ScoreReader`, `project.yml` and both
READMEs. No test changes its expectation: `WhatAScorePlaysTests` builds its own scores in code
and `WhatAWrittenScoreBecomesTests` reads from a string, so neither is touched. That is the
evidence this step is a refactor and not a change in behaviour. The app stays green and plays
identically.

A typo in a tune stops being a compile error and becomes a launch failure, which is the price of
not writing each piece twice. `ScoreReader` already proves reading a score at launch works.

**2. A page that draws the instrument.** `Web/`, TypeScript, no framework, and the strip and the
square at the right proportions, filling the visible area in both landscapes and saying to turn
the phone in portrait. No sound, no touches.

**3. The domain, test for test.** Port `Instrument`, `Playing`, `Scores` and the two use cases by
reading the Swift, with the test names carried across and the same numbers asserted. This step
either proves the layering was worth it or shows where it leaked.

**4. Sound.** An `AudioWorkletProcessor` holding the voice bank: the recording read with linear
interpolation, the 5 ms attack against the change's own fall, the ring down over 30 cycles, the
air spread across at most four reeds, the bend as one multiplication, the vibrato and its wander,
the cup as a state variable filter. Samples loaded from the shared folder through the index.

**5. Touches.** Pointer events into `PositionOnHarmonica`, the playing styles the measurement
allows, the square, the note row, the plates. At the end of this step the page is an instrument.

**6. The tunes.** `PlayScore` driving that instrument from the shared JSON, and the menu.

**7. Tilt.** The permission gate, the lean, the cup bar.

## Not in scope

No `.score` text reader on the web, no offline install, no saving anything, and no handling of a
phone call or the silent switch: they are corner cases and the page is not a product. Compiling
the Swift domain to WebAssembly is not on the table either — the audio, the motion and the views
would be rewritten for the browser regardless, so it would carry only the layer that is cheapest
to port, at the price of a toolchain and a multi-megabyte download.

If the page is ever made public rather than kept private for testing, the samples become a
question of their own: serving a commercial library from a public URL is not the same thing as
loading it from a folder on your own machine.
