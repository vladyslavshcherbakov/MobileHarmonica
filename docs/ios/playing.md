# Playing on the iPhone

What the iPhone adds to [the product's rules](../playing.md): a finger's measured width, the lean
that cups the hands, the screen's layout and refresh rate, and scores written as text.

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

## The screen

**Up to 120 Hz.** On a ProMotion iPhone the screen redraws, and hands over touches, up to 120
times a second, so a finger waits at most 8.3 ms before the instrument hears it. iOS lowers the
rate in Low Power Mode or when the phone is hot.

**The top bar keeps clear of the top edge.** A touch that starts in the first few points below the
top belongs to the system's Notification Centre, so the bar leaves 20 points of space above it
and its controls are 40 points tall, which puts their middles well below the edge.

**The screen fills the glass.** Only the square extends under the rounded corner and the notch on
the leading side. The strip stays clear of the notch and the home indicator, so the draw half of
every hole is always reachable.

**The square's size.** On a strip 844 by 340 points the square ranges from 84 to 340 points under
the pinch, which moves a hole's width between 70 and 44 points.

## Written scores

A score written as text in `Apps/iOS/Scores/` joins the tune menu at launch, ahead of the built-in
tunes. It names the key the music sounds in, the position, the tempo, and lines of pitches with
their lengths in beats. The format is in [Apps/iOS/Scores/README.md](../../Apps/iOS/Scores/README.md).
Score files are not committed: what someone writes there is theirs.

**Each written pitch becomes a hole and a breath** on the harmonica the score calls for: a plain
note when there is one, else a bend, else an overbend, and among equal choices the hole nearest
the one before, so the mouth moves as little as it can. A chord takes its breath from its lowest
pitch, and the rest must be reachable on that breath.

**The log says what the harmonica made of the piece** when it is read: how many bends and
overbends it needed, its widest leap in holes, and every pitch this harmonica cannot reach in
this key. A leap past three or four holes is one no mouth makes at speed.
