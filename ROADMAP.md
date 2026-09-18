# Roadmap

What is not built yet, why, and what each item is waiting on. Current state and everything
that already works are in [AGENTS.md](AGENTS.md).

Nothing here is scheduled. The order is by how much it changes the instrument.

## 1. Real samples

**Built, one layer.** The oscillator reads recorded notes instead of a sine, and neither
AudioKit nor `AppleSampler` was needed: the existing render callback already had the shape,
so a table read replaced `sin(phase)` and everything else stayed. `Domain/` and `Features/`
did not change at all, which is what the protocol seam was for.

**What is left: dynamic layers.** The GDD asks for soft, medium and hard per reed, so that
breath intensity picks a layer and blends at the boundaries and the tone gets dirtier towards
the edge rather than only louder. Today intensity is gain alone. The library supplies one
layer, so this needs either recordings that have layers or a different library.

**What is left: blow and draw.** The library records 19 pitches, not 20 reeds, so the two
breath directions share a timbre. A library sampled per reed would fix it.

**What is left: the vibrato layer.** The library ships a second set recorded with vibrato.
Crossfading it against the plain set by vibrato depth would give a real vibrato with a
continuous control, which the shared LFO cannot. Doubles the memory.

**Also unblocks.** The wah filter below, and the harmonics that a bent note should gain.

## 2. Device tilt

**What.** Read the device's attitude through CoreMotion and use it as a continuous control.

**Why.** Cupping and opening the hands around a harmonica is what produces the wah, and it
is a whole-instrument gesture rather than a finger one. Tilt is the closest thing a phone
has to it, and it costs no screen space, which the square and the strip are already
competing for.

**Blocked on.** A resonant filter sweeping a sine has no harmonics to emphasise, so wah
cannot be heard at all before item 1. Mapping tilt to something audible today, such as
vibrato rate, is possible but is not what tilt is for.

## 3. Playing from a score

**What.** The app plays a piece, or leads the player through one.

**The obstacle is not the notes.** A harmonica tab is hole numbers and breath directions,
which the domain already models exactly. What a tab has no notation for is **rhythm**: no
durations, no bars, no rests. A player cannot be driven from it and neither can a clock.

**Three shapes, in increasing cost.**

| Shape | Rhythm from | Cost |
|---|---|---|
| Guide mode | The player. The next hole lights and waits to be taken | Needs only what a tab already has |
| Timed playback, hand-timed | Durations entered by ear, once per note | Manual work per piece |
| Timed playback from MIDI | A MIDI file, which carries pitch and duration | No tab needed, and the rights question goes away |

**Also.** A published tab is someone's transcription of someone's composition. Embedding one
in the repository is a rights question, not a technical one. MIDI of a melody the user owns
or writes avoids it.

**Blocked on.** The user choosing a shape.

## 4. Mouth width

**Partly built.** `mouth` playing style takes the topmost finger and sounds every hole its
contact circle overlaps. What is missing is reach: the radius is used literally, so a contact
covers one hole and sometimes two, never the three or four a mouth covers. See item 5.

**What is left.** A rule that turns the reported radius into a mouth-sized span, or a
different input if the radius turns out not to vary.

**Why it matters more than it looks.** It is the same gap as two other things:

- A real mouth covers several holes and every covered reed sounds at **full volume**. There
  is no position-based blend between neighbours, which is what the app does now.
- Sliding along the strip is an **overlap**, not a crossfade: the old hole is still covered
  while the new one opens. The 20 ms crossfade the app uses is a de-click, not a model of
  the instrument.

So width and a physical slide are one feature, not two.

**Cost.** No audio work: the engine has been polyphonic since phase 2 and the mix is already
normalised, so four reeds at full gain cannot clip. What it needs is a control surface and a
decision about where it lives.

**Candidate inputs.** The contact radius, scaled (see item 5); a second finger in the
square; a third axis somewhere.

**Blocked on.** The measurement in item 5.

## 5. Contact radius

**Built, on trial.** `TouchTrackingView` reports `UITouch.majorRadius` with every touch, and
`mouth` style spends it as the mouth's half-width. Whether the value varies usefully on an
iPhone is still unmeasured, which is the whole question.

**How it is measured.** In `mouth` style the finger circle is drawn at the reported radius
rather than the fixed 56 points, and `PlayHarmonica` logs the width in hole widths at debug
level. Press flat, press on the tip, press with two pads. If the value swings between roughly
8 and 25 points the idea lives and item 4 gets its multiplier; if it sits on one number it is
dead and mouth width needs another input. `UITouch.force` is not an alternative: 3D Touch
hardware ended with the iPhone XS.

## 6. Overblows and overdraws

**Built.** The square's vertical axis rests in the middle, down bends and up overbends, and
the overbend pops at half travel rather than sliding in, because that is what the reed does.
What is left is the stretch below.

**What is left.** On the instrument an overblow can be bent further up once it has popped.
Here the axis stops at the overbend itself, so the travel above the threshold does nothing.
Adding it means the engine can no longer reach the shift with one multiplication per voice,
because the pop is an additive constant that differs per reed while the axis fraction is
shared. Worth doing only if the missing semitone is audible in practice.

**What.** The other half of pitch shaping. A bend pulls the higher reed of a chamber down
towards the lower one. An overbend does the opposite: it silences the reed that matches the
airflow and forces the other one to sound in its opening mode, about a semitone **above** its
own pitch. Blowing into a chamber whose blow reed is the lower one gives an overblow, which
is holes 1 to 6; drawing where the draw reed is lower gives an overdraw, holes 7 to 10.

| hole | blow | draw | overbend |
|---|---|---|---|
| 1 | C4 | D4 | overblow E♭4 |
| 4 | C5 | D5 | overblow E♭5 |
| 5 | E5 | F5 | overblow F♯5 |
| 6 | G5 | A5 | overblow B♭5 |
| 7 | C6 | B5 | overdraw C♯6 |
| 9 | G6 | F6 | overdraw A♭6 |

**Why.** Bend and overbend are complementary: on one hole in one breath direction exactly one
of them exists, never both, because a bend needs the higher reed and an overbend the lower.
So they share one axis with no conflict, and together they take the instrument from 8
responsive reeds out of 20 to 18. Only hole 5 draw and hole 7 blow stay dead, where the two
reeds are a semitone apart and neither move has room. The middle octave becomes fully
chromatic: E♭5, F♯5 and B♭5 exist no other way, which is what a diatonic harp is missing when
a tune leaves the key.

**Where it goes.** The square's vertical axis, which is half unused today. Down from rest
bends the pitch down, up from rest overbends it up, and on any given hole and breath only one
half is live. The other half dims its label the way the bend label already dims.

**Undecided.** Whether a missed overblow should be modelled: on the instrument it gives a
choke or a squeal, not the plain note, and here the threshold always lands cleanly.

**Blocked on.** Nothing for the stretch either, beyond deciding it is worth the engine
contract it costs.

## 7. Smaller wishes

| Item | Note |
|---|---|
| Vibrato rate as a third axis | Slow and wide against fast and narrow are different sounds. Rate is fixed at 5.5 Hz and there is no free control left in the square |
| Remember the pinched zone size | It returns to its natural side on every launch. Keeping it means storage, which the project does not have |
| Equal-loudness compensation | Draw sounds 1.0 to 1.6 dB louder than blow on holes 1 to 3 at the same amplitude, because the ear hears the higher note as louder. A real harmonica does this too, which is why blues lives on the draw notes. Decided against; recorded so it is not rediscovered as a bug |

## 8. Engineering debt

| Item | Note |
|---|---|
| `HarmonicaScreen` is 223 lines and does two jobs | Five members turn touch coordinates into what to draw, the rest render. Extracting the first five into their own type leaves the screen rendering only |
| Audio interruptions | Handled only through `scenePhase`. Nothing observes `AVAudioSession.interruptionNotification`, and a route change such as unplugging headphones is not handled |
| Localization | `HarmonicaPresenter` holds English literals |
| Copy-on-write on the render thread | One small allocation per buffer, about ninety a second. Not real-time safe in principle. The alternative is a manually allocated `os_unfair_lock` held across the whole buffer |
| `@MainActor` on the whole view model | Would hand the thread check to the compiler instead of the hand-placed annotations on two async functions. Needs `MainActor.assumeIsolated` in the `@StateObject` autoclosure and bridges at the `Slider` binding and the `UIViewRepresentable` callback |
