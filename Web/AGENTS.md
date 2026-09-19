# MobileHarmonica on a page

The same instrument as the iOS app, in Safari on an iPhone. The plan and the reasons behind it
are in [ROADMAP.md](../ROADMAP.md); what the instrument itself does, and why every number is
that number, is in [AGENTS.md](../AGENTS.md). This file is only what is different here.

## Quick start

```sh
npm install        # typescript, and nothing else
npm test           # tsc, then the ported tests on node
npx http-server -p 8123 .
```

Then open `http://<this machine>:8123` on the phone, in landscape. The page opens with a
**tap to play** button because an `AudioContext` only starts inside a gesture; the same tap asks
for motion.

`npm run build` is `tsc` alone. There is no bundler: TypeScript compiles to ES modules under
`dist/`, which Safari loads itself, so a stack trace on the phone names a file that exists on
disk. `dist/` and `node_modules/` are not committed.

`.github/workflows/pages.yml` runs the tests and publishes this folder to GitHub Pages on every
push that touches it. The site root is `Web/`, so `index.html` sits at the root of the published
URL and every path in the page is relative to it.

`configure-pages` runs with `enablement: true`, which switches the repository's Pages source to
GitHub Actions itself. Without it the first run failed on a repository still set to deploy from a
branch, and GitHub's own `pages-build-deployment` published the repository root instead, which
has no `index.html` and answers 404.

## Layout

```
Web/
  index.html      the whole markup, no template engine
  styles.css      the whole style
  src/
    domain/       ported from Apps/iOS/Domain line for line
    audio/        the AudioWorkletProcessor and the engine that talks to it
    motion/       devicemotion behind its permission prompt
    features/     view state, presenter, view model, renderer, touch adapter
    logging/      the timestamped log
    app/          composition root and entry point
  tests/          the app's tests, same names, same numbers
```

The domain is a rewrite, not a port of a port: every file under `src/domain` was written by
reading its Swift original, and the tests carry the Swift test names and the Swift numbers
across, which is what makes the two instruments the same instrument.

## What is deliberately different

**The mouth is a number, not a measurement.** `UITouch.majorRadius` has no counterpart here:
where the hardware reports a point rather than an area, `Touch.radiusX` reads 1 whatever the
standard says. So the page asks for the width instead, `mouth 1` to `mouth 4` in the top bar,
and `PositionOnHarmonica` carries no contact width at all. A contact covers the holes whose
centres fall inside a span that many holes wide, so four is four rather than three and a half,
and a span at the end of the comb hangs over the edge as a mouth does. At one hole the span is
dropped and the contact takes the hole it is over, which is what makes it exact rather than
nearly exact. The boundary is half open with a tolerance, because a finger resting exactly on a
hole centre with an even width would otherwise flip between four holes and five on the last bit
of a double.

`PlayingStyle` keeps its three cases and its two questions, so the width is the third control
rather than a fourth style. One mouth at one hole is still not offered.

**The sound is generated, not recorded.** `SineWaveAudioEngine` drives a voice bank reading a
sine wavetable, because the WAV library is not committed and a page that has to be handed the
samples first is not a page anyone can open. Everything above the bank is the shape the sampled
engine needs: a `SampleBank` of frames plus a `RecordedNote` per pitch, read at
`wanted ÷ recorded` speed. Writing the sampled engine is swapping `sineBank()` for a loader and
nothing else, which is why the tests for the oscillator are the app's tests unchanged: they
always ran on a synthetic bank.

**The worklet holds no locks.** `Oscillator` in the app merges a buffer's worth of progress back
into a bank the main thread may have re-sounded meanwhile, because both threads reach it. Here
the audio thread owns everything and the main thread only posts messages, which the worklet
delivers between render quanta, so the merge, the voice numbering it needed and the copy per
buffer are all gone. The voice number stayed anyway: it is what lets one pitch sound twice, which
is what a note taken again before it has faded needs.

**The oscillator is one file.** `harmonicaWorklet.ts` imports nothing at run time, because
whether Safari's `addModule` accepts a module with static imports is not a thing to find out on a
phone. Types come in through `import type`, which tsc erases. The processor class is defined
inside `registerHarmonicaProcessor()` so that the same file can be imported by the tests on node,
where `AudioWorkletProcessor` does not exist.

**Nothing reads a `.score` file**, so `Fingerings` and `Playability` are not ported: what they
answer is what a written pitch costs on the harmonica, and nothing here writes pitches. The seven
tunes are TypeScript for now. They are the one thing this repository says twice, and the roadmap
ends by making them one JSON file read by both platforms.

## The page in Safari

**The sound plays over the silent switch.** Safari puts a bare `AudioContext` in the `ambient`
audio session, which the hardware mute switch silences, so a page that is nothing but sound went
quiet in a pocket. `navigator.audioSession.type = 'playback'` says this audio is the point of the
page rather than decoration. Only Safari implements it, so the property is read before it is set.

**The screen is filled by a button.** The Fullscreen API reached iPhone in Safari 17.4; before
that only a video element could go fullscreen. The button asks `document.documentElement`, falls
back to the `webkit` spelling, and hides itself where neither exists, so nothing on the bar
promises what the browser cannot do.

A refused request says so rather than doing nothing. Safari can hold the method and still reject
the call, which looked from the phone like a dead button, so the rejection now opens a note: add
the page to the home screen, where it runs with no browser around it at all, which is what
`apple-mobile-web-app-capable` in the markup is for. The note carries the rejection's own words,
because a button that fails silently costs a round trip to a device to diagnose.

The instrument fills the visible area in either landscape: `dvh`, `--appHeight` set from
`visualViewport` on every resize, `env(safe-area-inset-*)` for the notch, `touch-action: none`
and `overscroll-behavior: none` so nothing scrolls or rubber bands. In portrait the page says to
turn the phone, because a ten hole strip across a portrait screen is not an instrument. Only the
square sits in the leading inset; the strip keeps its trailing and bottom insets, exactly as the
app does.

Touches arrive as pointer events, captured per surface, so the strip and the square never see
each other's fingers. Two fingers in the square are a pinch and stop shaping the tone, which is
what the app's recogniser does by cancelling the touches beneath it.

**The renderer holds its elements and the last state it drew**, and touches a node only where the
new state differs. That is the whole reason there is no framework: the view state is one already
assembled value, the only thing moving at sixty frames a second is two or three finger circles,
and those are absolutely positioned elements moved by `transform`. Swapping the renderer for Lit
or a canvas means replacing `render(state)` and the pointer adapter, and nothing below them
notices.

## Verified, and not

Run on node: the domain, the use cases and the oscillator, 65 tests. Run in Chromium through
Playwright: the page lays out, the plates light, the note row names the bent and overbent notes,
the pinch resizes the square, a tune plays, and the worklet renders 440 Hz, bends it three
semitones to 370 and rings down to silence.

Not run anywhere yet: **Safari on an iPhone**, and **the tilt**. The lean reads
`accelerationIncludingGravity.y` and flips its sign on `screen.orientation.angle === 90`, and
which way round that lands on a real phone has not been checked. If leaning the wrong way closes
the cup, the fix is that one comparison in `deviceTilt.ts`.
