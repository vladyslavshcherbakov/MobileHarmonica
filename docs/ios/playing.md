# Playing on the iPhone

What the iPhone adds to [the product's rules](../playing.md): a finger's measured width, the lean
that cups the hands, the screen's layout and refresh rate, the settings screen, and scores written
as text.

## A finger's width

The iPhone reports how wide each touch is, and a finger covers every hole within that width
either side of its centre, taken as reported. A fingertip reports far less than a hole's width,
so one finger usually covers one hole, and two when it straddles a boundary. Where width counts,
each finger's circle is drawn at the width the phone reported, and the width is written to the
log in hole widths at debug level.

## Cupped hands

**Leaning the phone closes the hands around the harmonica.** Level in landscape the hands are
open. Lowering the screen's right edge closes them, fully at thirty degrees, whichever way round
the phone is held. Three degrees either side of level count as level, since a hand never holds
a phone exactly flat. Cupping is a gesture of the whole instrument and both hands are already on
the glass, so it takes no space on the screen.

**Cupping can be turned off** in the settings. Then the lean is not read at all, the hands open,
and the top bar stops showing how far they are closed.

## The screen

**Up to 120 Hz.** On a ProMotion iPhone the screen redraws, and hands over touches, up to 120
times a second, so a finger waits at most 8.3 ms before the instrument hears it. iOS lowers the
rate in Low Power Mode or when the phone is hot.

**The top bar keeps clear of the top edge.** A touch that starts in the first few points below the
top belongs to the system's Notification Centre, so the bar leaves 20 points of space above it
and its controls are 40 points tall, which puts their middles well below the edge.

**The screen fills the glass.** Only the shaping pad extends under the rounded corner and the notch on
its side of the screen. The strip stays clear of the notch and the home indicator, so the draw half
of every hole is always reachable.

**The shaping pad's size.** On a strip 844 by 340 points the pad ranges from 84 to 340 points under
the pinch, which moves a hole's width between 70 and 44 points.

## Settings

A gear at the right end of the top bar opens the settings screen. Opening it silences the
harmonica, as leaving the app does, even with a finger still on the strip, and the fingers it held
are forgotten. What is chosen there is kept between launches and applies when the harmonica screen
is back.

| Setting | Choices | Out of the box |
|---|---|---|
| Playing style | The three styles, named as full sentences | Many fingers, many notes |
| Cup the hands by leaning the phone | On or off | On |
| Shaping pad | Left or right of the holes. Hole 1 stays at the left end of the strip either way | Left |
| Shaping pad size | A slider from 0, the smallest the pinch allows, to 1, the largest | 0.4 |

**The size slider and the pinch set one value.** The slider's range runs evenly across the sides the
pad can take on this screen, so 1 is the pad the pinch reaches at its largest. A pinch on the
pad moves the slider, and the slider sets what the next pinch starts from.

## Written scores

A score written as text in `Apps/iOS/Scores/` joins the tune menu at launch, after the built-in
tunes, so they keep the same numbers as on the page. It names the key the music sounds in, the position, the tempo, and lines of pitches with
their lengths in beats. The format is in [Apps/iOS/Scores/README.md](../../Apps/iOS/Scores/README.md).
Score files are not committed: what someone writes there is theirs.

**Each written pitch becomes a hole and a breath** on the harmonica the score calls for: a plain
note when there is one, else a bend, else an overbend, and among equal choices the hole nearest
the one before, so the mouth moves as little as it can. A chord takes its breath from its lowest
pitch, and the rest must be reachable on that breath.

**The log says what the harmonica made of the piece** when it is read: how many bends and
overbends it needed, its widest leap in holes, and every pitch this harmonica cannot reach in
this key. A leap past three or four holes is one no mouth makes at speed.

## Tunes

**A tune starts a second after it is chosen**, so the menu has closed and the hands are ready
before the first note. The stop button is already there during that second, and touching the strip
cancels the tune before it sounds, as it does once it plays.

**The stop button names the tune**, as `■ The Star-Spangled Banner`, and grows to fit the whole
name, since the top bar has room for it.
