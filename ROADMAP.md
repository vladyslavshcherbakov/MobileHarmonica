# Roadmap — the same instrument as a page

The app becomes a web page, playable in Safari on an iPhone, and the two platforms share what is
genuinely shared instead of keeping two copies of it. Current state and everything that already
works are in [AGENTS.md](AGENTS.md), including its own [Not built](AGENTS.md#not-built) list,
which is about the instrument and stays where it is.

Nothing here is scheduled. The order below is the order the work has to happen in, because each
step needs the one before it.

## Contents

1. [Constraints](#constraints)
2. [What is shared](#what-is-shared)
3. [Where the files live](#where-the-files-live)
4. [Layer by layer](#layer-by-layer)
5. [The presentation layer](#the-presentation-layer)
6. [The page in Safari](#the-page-in-safari)
7. [The steps](#the-steps)
8. [Not in scope](#not-in-scope)

## Constraints

| | |
|---|---|
| Browser | Safari on iPhone. Only that one |
| Orientation | Landscape, both directions. A page cannot lock it, so it is asked for |
| Language | TypeScript, compiled to ES modules, no bundler |
| Framework | None. See [The presentation layer](#the-presentation-layer) |
| Dependencies | None, the same as the app |
| Reference | What WebKit implements, not what every browser agrees on |
| Hosting | A static page, private while it is being tested |

**One browser is a decision, not a shortcut.** Building for Safari alone means WebKit's API is
the API: anything it ships is available, prefixed or not, with no fallback to write and no
polyfill to carry. It also means a cross-browser support table is the wrong question to ask.
"Not supported in some widely used browsers" says nothing about whether this phone does it, and
the only thing that answers that is the phone.

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

## The presentation layer

**No framework, because the layer a framework sells is already built.** `HarmonicaPresenter`
returns a `HarmonicaViewState` of finished strings and flags, so all a view has to do is put that
value into a dozen elements. There is no state to observe and nothing to reconcile: the state is
one value, already assembled, and already deduplicated, since the view model never publishes one
that equals the last. A virtual DOM diffing ten plates sixty times a second is the heaviest way
to do the cheapest job in the project.

**TypeScript rather than plain JavaScript**, because the domain is 1389 lines of values with
invariants in them — semitones, fractions of travel, hole numbers, bend ranges — and types are
the cheapest way not to lose one in the crossing. `tsc` is the whole build.

**No bundler.** TypeScript to ES modules, which Safari loads itself. A stack trace names a file
we wrote rather than a chunk, the inspector attached to the phone shows the same code that is on
disk, and `AudioWorklet.addModule()` takes a module URL anyway.

**DOM rather than canvas.** Canvas looked right at first, since this project decided against
accessibility long ago and that is the usual argument for elements over pixels. It is still
wrong here: the view state changes rarely, and the only thing moving at sixty frames a second is
two or three finger circles, which are absolutely positioned elements moved by `transform` and
handed to the compositor. Against that, elements give the layout, the text, `dvh` and
`env(safe-area-inset-*)` for free, which is most of the requirement below, and a canvas would
have every one of those written by hand.

**What makes it replaceable is the seam, not the choice.** The presentation layer is
`present(harmonica) -> ViewState` and `render(state)`, plus an adapter turning pointer events
into `PositionOnHarmonica`. The renderer holds nothing but its element references and the last
state it drew, which is what lets it be swapped for Lit, for Svelte, or for a canvas, without
anything below it noticing. Keeping the renderer free of state is the rule that has to survive,
whatever it is written with.

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

**The contact width is set on the page, not read off the finger.** Where the hardware reports a
point rather than an area, `Touch.radiusX` reads 1 whatever the standard says, so the width that
`UITouch.majorRadius` gives the app has no counterpart here. `Touch.force` is not the way round
it either, for the same reason it is not on the app: the hardware that varied it ended with the
iPhone XS.

So the page asks for the width instead of measuring it, and that is the one place where it
deliberately differs from the app. `PlayingStyle` keeps its meaning, several fingers or one
mouth, and the width becomes a number from one hole to four. Three of the four combinations are
worth offering: several fingers at one hole each, several fingers at a chosen width each, and
one mouth at a chosen width. One mouth at one hole is an instrument that plays no chords, so it
is not offered, the same as on the app.

The holes a contact covers should be the ones whose centres fall inside a span that many holes
wide, so four is four rather than three and a half, and a span at the end of the comb hangs over
the edge as a mouth does. At one hole the span is dropped and a contact takes the hole it is
over, which is what makes it exact rather than nearly exact.

None of this touches the app, where the radius is real, still read on every touch and still
logged, and whether it varies usefully on an iPhone is still the question it always was.

## The steps

Each one ends somewhere that runs, and they are in this order for one reason: **a harmonica that
plays comes first, and everything about written music comes last.** The page is an instrument
before it is a jukebox, so nothing that only serves the demo is allowed to hold up the
instrument, and nothing touches the app until the page can be played.

**0. One measurement.** A throwaway page that prints `touch.radiusX`, `radiusY` and the tilt
reading. Press it flat, on the tip, and with two pads. This answers the width question for the
app as well.

**1. A page that draws the instrument.** `Web/`, TypeScript, no framework, and the strip and the
square at the right proportions, filling the visible area in both landscapes and saying to turn
the phone in portrait. No sound, no touches.

**2. The instrument, test for test.** Port `Instrument`, `Playing` and `PlayHarmonica` by reading
the Swift, with the test names carried across and the same numbers asserted. `Scores` and
`PlayScore` are not in this step: nothing plays a score yet and porting them now would be code
with nothing to run against. This step either proves the layering was worth it or shows where it
leaked.

**3. One folder for the samples.** Create `Resources/Samples/` with its index, point
`RecordedHarmonica` and `project.yml` at it, and have the page read the same folder. This is the
only thing the app has to change before the page makes a sound, and it changes nothing about how
the app behaves.

**4. Sound.** An `AudioWorkletProcessor` holding the voice bank: the recording read with linear
interpolation, the 5 ms attack against the change's own fall, the ring down over 30 cycles, the
air spread across at most four reeds, the bend as one multiplication, the vibrato and its wander,
the cup as a low pass.

**5. Touches.** Pointer events into `PositionOnHarmonica`, the playing styles with the width the
page asks for, the square, the note row, the plates.

**6. Tilt.** The permission gate, the lean, the cup bar. **At the end of this step the page is a
harmonica**, and it has needed one mechanical change to the app and nothing else.

**7. One copy of the music, and the demo.** Only now. Write the seven tunes as JSON into
`Resources/Scores/`, teach `Score` to read one, delete the Swift tune files, add the JSON exit to
`ScoreReader`, port `Scores` and `PlayScore`, and give the page the menu. Touches
`BundledScores`, `CompositionRoot`, `Score`, the seven tune files, `ScoreReader` and both
READMEs. No test changes its expectation: `WhatAScorePlaysTests` builds its own scores in code
and `WhatAWrittenScoreBecomesTests` reads from a string, so neither is touched, which is the
evidence this is a refactor and not a change in behaviour.

A typo in a tune stops being a compile error and becomes a launch failure, which is the price of
not writing each piece twice. `ScoreReader` already proves reading a score at launch works.

**Why last.** It is the only step that rewrites working code in the app, and it buys the app
nothing: the tunes already play there. It pays off on the page, which cannot use it until the
page has an instrument to play it on. Doing it first would mean changing something that works,
for a consumer that does not exist yet, and then carrying that change through every step that
follows.

## Not in scope

No `.score` text reader on the web, no offline install, no saving anything, and no handling of a
phone call or the silent switch: they are corner cases and the page is not a product. Compiling
the Swift domain to WebAssembly is not on the table either — the audio, the motion and the views
would be rewritten for the browser regardless, so it would carry only the layer that is cheapest
to port, at the price of a toolchain and a multi-megabyte download.

If the page is ever made public rather than kept private for testing, the samples become a
question of their own: serving a commercial library from a public URL is not the same thing as
loading it from a folder on your own machine.
