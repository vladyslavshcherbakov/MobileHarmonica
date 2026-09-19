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

The button says **loading the instrument** and refuses the tap until the core has been fetched
and compiled, because nothing is listening to it before that: the markup is served in one hit and
the module behind it weighs tens of megabytes, so on a phone there were seconds in which the
button looked ready and did nothing. The loader says the same thing in the log, naming the
address it reads and how long the compile took.

`npm run build` is `tsc` alone. There is no bundler: TypeScript compiles to ES modules under
`dist/`, which Safari loads itself, so a stack trace on the phone names a file that exists on
disk. `dist/` and `node_modules/` are not committed.

**Every publish moves the code to a new address.** The page is a tree of ES modules at fixed
paths, and a browser is free to take some of them from its cache and some from the network, which
on a Mac produced a page assembled from two builds at once: it hung on loading, and then played a
second late, both of them faults that had already been fixed. `npm run stamp` renames `dist` to
`dist-<commit>` and rewrites the page's one script path to match, so a publish leaves nothing
behind that a cache can mix in. Everything else follows: the modules import each other relatively,
and the worklet's url is built from `import.meta.url`. The recordings keep their address, since
they change rarely and weigh nineteen megabytes.

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
    core/         the WASI shim, the loader, and the wrapper around HarmonicaCore
    audio/        the AudioWorkletProcessor and the engine that talks to it
    features/     view state, presenter, view model, renderer, touch adapter, tune player
    logging/      the timestamped log
    app/          composition root, entry point, and the adapter for Telegram
  tests/          what the page itself promises: the presenter and the oscillator
```

**The instrument is not here any more.** It is `Core/`, compiled to WebAssembly, and the page
loads it. There is no second copy of the rules to keep in step, no second set of tunes, and the
tests that check bend ranges and overbends live with the Swift that implements them. What is
left here is what only a browser has: the sound, the screen, the fingers, and the clock.

**The boundary is narrow on purpose.** Fingers go in as one buffer of doubles, because they
move on every touch. The harmonica's state comes out as JSON, because it is read once per change
and a declared type beats a hand-written bag. The core calls back out for two things only, the
audio engine and the log, declared in Swift with `@_extern` and provided here as the `harmonica`
import module.

**WASI is shimmed rather than depended on.** Foundation inside the module asks for a clock,
random bytes, an environment and somewhere to write; the shim answers those and refuses the rest,
so the page carries no WASI package. `_initialize` is what the loader calls after instantiating:
the module is built as a reactor, so it survives its own start and keeps its exports.

**Refusing a call and not naming it are different things.** A name the module imports and the
shim does not carry is a `LinkError` that kills the whole module before a line of it runs, which
is how `fd_fdstat_set_flags` left the page dead on `reading the instrument`. So the shim names
every one of preview1's forty-six calls: a dozen it answers, the rest return `ENOTSUP`, and a
test lists the specification's names beside what the shim exports, because the one thing that
cannot be found by reading our own code is what Foundation decided to import.

**Nothing that is nil crosses as missing.** Swift's synthesized encoder writes an optional with
`encodeIfPresent`, so a nil leaves the key out altogether, and `undefined` is not `null`: a note
with no `shakenWith` was read on this side as a note that is shaken, every note stepped as a
shake, and the odd steps sounded a hole of `undefined`, which reaches the core as a `NaN` hole
number and traps the module. One note kept sounding and the tune never moved again, because a
trap rejects the promise the player is waiting on. So both states that carry an optional spell
out their keys and encode them with `encode` rather than `encodeIfPresent`, and the page's types
stay true: `number | null`, never `undefined`.

**A hole that is not a hole is refused, and a tune that dies says so.** The core reads the holes
it is asked for out of a buffer of doubles, and turning one into an integer used to be enough to
bring the whole module down: one `NaN` from this side and nothing worked again until the page was
reloaded. It now takes only a value that is exactly a hole number and writes the rest to the log.
The player's failures reach the log too: the promise a tune runs on had no `catch`, so a module
that trapped mid-tune left a reed sounding and said nothing anywhere. A tune now names itself
when it starts, when it ends, and when it stops because something threw.

**The clock stays on this side.** `PlayTheTune` walks a tune's events, sleeping between them, and
drives the instrument through the same calls a finger does. The core has no executor to sleep on,
and the project's own rule already says time lives in the player. What it cannot know by itself
it asks the core for once at startup: how far each reed bends, and the four lengths in
`ScoreTiming` that say how a written note is articulated, slid, shaken and bent. Those are the
music's, not the page's, so they are read rather than repeated.

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

**A note name shrinks to its hole, because CSS has no `minimumScaleFactor`.** The app writes the
rule as `.lineLimit(1)` and `.minimumScaleFactor(0.6)`, and a hole on a phone in full screen is
about 54 points wide while `(G4 overblow)` at ten pixels wants about 69. Here each label is a
flex item as wide as its own text, and the renderer compares that width with the hole's and
applies a `scale()` down to the same floor of 0.6. The cell clips what is still too long, as the
app does. The measurement is a forced layout read, so it happens only where the text changed,
which the renderer already knows, and once more from `layOutTheZone` because a pinch changes the
hole's width without changing a word in it.

**There are no cupped hands here.** The phone closes them by leaning, read through CoreMotion,
which asks nobody. A browser gives the same reading only through `devicemotion`, and iOS hands it
over only if `requestPermission` is called inside the gesture that started everything, which is
the same tap that starts the audio. It never worked in Safari and does not work inside Telegram
either, so the page lost the control, the reading and the bar in the top row. What stays is the
low pass in the worklet: it is the phone's own code, it is tested, and the module imports
`cupHands` whether or not anything calls it, so removing that would refuse the core at link time.
On the page the hands simply never close.

**The recordings reach the page over the network, not out of a bundle.** The app enumerates its
`Samples` folder; a browser can fetch a name but cannot list a directory, so the folder carries
`index.json` and both the page and the copy step read that. `npm run samples` copies
`Resources/Samples` into `Web/samples` and writes the index, and the Pages workflow runs it
before publishing, so the shared folder stays the one place the WAV files live.

Loading is `fetch` plus `decodeAudioData` in place of `AVAudioFile`, and the arithmetic around it
is the app's: each file is mixed to mono, its loop is seconds 1 to 4, frames past second 4 are
never kept, and the whole library ends up in one contiguous `Float32Array` that crosses to the
worklet once, transferred rather than copied. `decodeAudioData` resamples to the context's rate
on the way in, so a `RecordedNote` carries that rate and the voice still reads at
`wanted ÷ recorded` speed.

The sine bank stays, and is now only what the oscillator's tests run on, exactly as
`SineSamples` is on the app. The processor starts on a silent bank and says nothing until the
recordings arrive, so a page that cannot load them is silent rather than buzzing — and
`prepare()` waits for them, so the screen reports sound as unavailable the same way the app
does.

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

**The instrument installs as an app.** Safari on iPhone does not carry the Fullscreen API at
all, so the only way to lose the browser's own bars there is to be started from the home screen.
`manifest.webmanifest` asks for `fullscreen` display and a landscape orientation, and since iOS
16.4 that manifest is what Safari reads; the old `apple-mobile-web-app-capable` meta tag stays
beside it as the fallback Safari uses when it cannot load the manifest. Started that way, the
page hides its own advice about installing, because there is nothing left to install.

**That advice is hidden until the page knows it is needed.** It asks for a positive answer to
two questions, that the browser carries no Fullscreen API and that the page is not already
running from the home screen, and only then does the start screen show it. It used to be shown
by default and taken away by whichever answer came first, and the markup stands long before any
script has run: a desktop browser read the whole advice while it downloaded the core, and a
phone that had installed the page read it too whenever the standalone check was the one that had
not arrived yet.

**Filling the screen and starting the sound are two taps, not one.** They were one for a
while, and it hung the page: entering fullscreen spends the transient user activation, and
Safari will not start an `AudioContext` without one, so `resume()` never settled and the start
screen sat on "loading" with nothing in the log. The log now names the context before that wait
and its state after, so the same hang would say where it is.

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

**The top bar cannot push a control off the screen.** The page has no scrolling and no zoom, so
anything that overflows is simply cut off, and on a phone the bar is squeezed twice over: the
safe area takes a notch's width off the side, and Safari's own select controls are wider than the
ones a desktop draws. Every control may now shrink, the two buttons may not, the bar scrolls
sideways if even that is not enough, and the button that fills the screen sits first, at the
leading edge, where nothing can push it out of reach.

Touches arrive as pointer events, captured per surface, so the strip and the square never see
each other's fingers. Two fingers in the square are a pinch and stop shaping the tone, which is
what the app's recogniser does by cancelling the touches beneath it.

**The renderer holds its elements and the last state it drew**, and touches a node only where the
new state differs. That is the whole reason there is no framework: the view state is one already
assembled value, the only thing moving at sixty frames a second is two or three finger circles,
and those are absolutely positioned elements moved by `transform`. Swapping the renderer for Lit
or a canvas means replacing `render(state)` and the pointer adapter, and nothing below them
notices.

## Inside Telegram

**The mini app is this page.** Telegram opens it in its own window, so the same core, the same
worklet and the same recordings serve both; what it needed was an adapter for that window, in
`app/telegram.ts`. A bot in BotFather points at the published address, and nothing runs anywhere
else.

The window gets in the instrument's way in three places, and each has an answer that arrived in
Bot API 7.7 or 8.0, so each is asked for only if the client has it and named in the log if it
does not. A vertical swipe closes a mini app, and a vertical drag is how the instrument takes a
breath, so `disableVerticalSwipes` turns that gesture off. The window opens as a portrait sheet,
so it asks for full screen. And the orientation needs both of their calls in the right
order. The adapter first locked at launch, which nailed the window to the portrait sheet it opens
in: the phone was never seen to turn. It now asks to unlock, so the window may follow the phone
at all, and locks once the viewport is landscape, so a turn of the wrist mid-phrase cannot take
the instrument away. Locking at launch and locking after the turn are the same call a second
apart, and only the second one is right. Telegram also reports where its own controls sit, so its insets
reach the key bar as two custom properties, and its viewport events reach the page as a resize,
because the window that changed is theirs while the screen listens for the browser's.

The script is fetched from telegram.org only when the address carries their launch mark, so a
page opened in a browser loads nothing from them and behaves exactly as before.

## Verified, and not

Run on node: the presenter, the oscillator, how a recording is read and looped, what a stopped
tune leaves behind, what the module asks the browser for and what Telegram is asked for, 38
tests. The instrument itself is tested in the package, since the page runs that same code. Run in
Chromium through
Playwright: the page lays out, the plates light, the note row names the bent and overbent notes,
the pinch resizes the square, a tune plays, and the worklet renders 440 Hz, bends it three
semitones to 370 and rings down to silence. On the real library: nineteen recordings load in
under two seconds, hole 4 blown comes out as 522 Hz with its partials at 1044 and 1572, and a
full bend on a three semitone reed moves all of them by 1.19, which is the three semitones.

Not run anywhere yet: **Telegram**. No client exists in the container the page is built in, so
every call in the adapter is written from their documentation and from what a device reported
back. A test holds the adapter to what an old client can do, which is the one part of it that can
be proven here: it asks for nothing the client lacks and says in the log what was missing.
