# Roadmap

What is not built yet, why, and what each item is waiting on. Current state and everything
that already works are in [AGENTS.md](AGENTS.md).

Nothing here is scheduled. The order is by how much it changes the instrument.

## 1. Real samples

**What.** Replace the synthesised sine with recorded reeds, three dynamic layers per reed
(soft, medium, hard) as the GDD's phase 5 describes.

**How.** AudioKit through Swift Package Manager, `AppleSampler` behind the existing
`AudioEngineProtocol`. Nothing in `Domain/` or `Features/` changes: the protocol is the only
seam, and it already carries pitch, bend range, intensity and vibrato.

The vertical distance from the centre line already produces a breath intensity from 0.2 to
1.0. With samples it does two jobs instead of one: it picks which layer sounds and blends
between layers at the boundaries, so the tone gets dirtier towards the edge rather than only
louder. The compressive curve stays; the layers ride on it.

The key slider stops transposing MIDI numbers and drives a pitch node instead.

**Blocked on.** The samples. The user records or supplies them. Twenty reeds times three
layers is sixty files, plus whatever the bends need if they are not pitch-shifted.

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

**What.** One control for how many adjacent holes sound at once, from one to four.

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

**Candidate inputs.** A second finger in the square; `UITouch.majorRadius`, which needs
measuring first (see item 5); a third axis somewhere.

**Blocked on.** The user choosing the input.

## 5. Contact radius

**What.** Read `UITouch.majorRadius` in `TouchTrackingView`, which already receives the
touches, and see whether the area of the fingertip varies usefully on an iPhone.

**Why.** If it does, it is the natural input for mouth width: press flat to cover more holes,
press with the tip to isolate one. That is the real gesture.

**Blocked on.** A measurement, not a decision. Twenty lines that log the radius while a
finger presses flat, on its tip and with two pads. If the value swings between roughly 8 and
25 points the idea lives; if it sits on one number it is dead. `UITouch.force` is not an
alternative: 3D Touch hardware ended with the iPhone XS.

## 6. Smaller wishes

| Item | Note |
|---|---|
| Vibrato rate as a third axis | Slow and wide against fast and narrow are different sounds. Rate is fixed at 5.5 Hz and there is no free control left in the square |
| Remember the pinched zone size | It returns to its natural side on every launch. Keeping it means storage, which the project does not have |
| Equal-loudness compensation | Draw sounds 1.0 to 1.6 dB louder than blow on holes 1 to 3 at the same amplitude, because the ear hears the higher note as louder. A real harmonica does this too, which is why blues lives on the draw notes. Decided against; recorded so it is not rediscovered as a bug |

## 7. Engineering debt

| Item | Note |
|---|---|
| `HarmonicaScreen` is 223 lines and does two jobs | Five members turn touch coordinates into what to draw, the rest render. Extracting the first five into their own type leaves the screen rendering only |
| Audio interruptions | Handled only through `scenePhase`. Nothing observes `AVAudioSession.interruptionNotification`, and a route change such as unplugging headphones is not handled |
| Localization | `HarmonicaPresenter` holds English literals |
| Copy-on-write on the render thread | One small allocation per buffer, about ninety a second. Not real-time safe in principle. The alternative is a manually allocated `os_unfair_lock` held across the whole buffer |
| `@MainActor` on the whole view model | Would hand the thread check to the compiler instead of the hand-placed annotations on two async functions. Needs `MainActor.assumeIsolated` in the `@StateObject` autoclosure and bridges at the `Slider` binding and the `UIViewRepresentable` callback |
