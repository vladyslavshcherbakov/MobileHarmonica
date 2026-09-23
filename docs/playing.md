# Playing

How a hand plays the instrument: what each control does, how breath and holes are decided, the
playing styles, shaping the tone, what the screen shows, and the built-in tunes. These rules hold
on every platform. What one platform adds or does differently is in [docs/ios/](ios/) and
[docs/web/](web/).

## Contents

1. [The screen](#the-screen)
2. [Controls](#controls)
3. [Holes and breath](#holes-and-breath)
4. [Playing styles](#playing-styles)
5. [Shaping the tone](#shaping-the-tone)
6. [What the screen shows](#what-the-screen-shows)
7. [Tunes](#tunes)

## The screen

The strip of ten holes fills the right of the screen and the shaping square sits on its left, for
a right-handed player: the right hand picks holes, the left thumb shapes. Hole 1 is at the left
end of the strip, where it is on the instrument. A bar along the top holds the key slider, the
playing style menu and the tune menu, and a row above the plates names what is sounding. On the
iPhone the square can stand on either side of the strip, and the playing style is chosen on the
settings screen instead of in the bar, as [docs/ios/playing.md](ios/playing.md#settings) says.

## Controls

| Control | Input | Effect |
|---|---|---|
| Hole | A finger on the strip | Sounds that hole. The playing style decides how many fingers count and how many holes each covers |
| Breath direction | Height of the **topmost** finger on the strip | On or above the centre line blows, below draws |
| Breath intensity | That finger's distance from the centre line | 0.2 on the line to 1.0 at the edge |
| Bend | A finger below the middle of the square | From nothing at the middle to the reed's full range at the bottom |
| Overbend | A finger above the middle of the square | Past half the travel, the reed pops to its overbend |
| Vibrato | A finger's position across the square | None at the left to full depth at the right |
| Key | Slider in the top bar | Chooses which harmonica is in your hands, G to F♯ |
| Playing style | Menu in the top bar, on the settings screen on the iPhone | How many fingers count, and how many holes each one covers |
| Square size | Pinch on the square, or the size slider on the iPhone's settings screen | Resizes the square between 0.45 and 2 times its natural side, trading width with the strip |

## Holes and breath

**One breath for the whole instrument.** One mouth gives one airflow, so the topmost finger on the
strip decides the direction and the intensity for every sounding hole. The centre line itself
blows. Breath is read from the centre of that finger's contact, so the edge of a pad crossing the
line changes nothing.

**The centre line has slack.** Within six per cent of the strip's height either side of the line,
the instrument holds whatever it is already sounding: the breath, the hole and the intensity.
Leaving the slack applies the new breath and the new hole together. This is what makes a move
such as hole 2 drawn to hole 3 blown playable: the finger crosses the line and a hole boundary
inside the slack, so the next note heard is the one aimed at, not hole 2 blown or hole 3 drawn on
the way. A chug still works, since a finger crossing the line without moving sideways stays on
its hole, and a slide still works, since a finger running along the strip away from the line
never enters the slack.

**Only fingers on the strip count.** A finger that slides off the side neither sounds a hole nor
decides the breath, and the topmost of the fingers left takes over.

**Chords are the point.** Two fingers on adjacent holes are the chord a mouth makes. Two holes
apart they are a tongue-block split. Two on one hole sound one note. Nothing caps the number of
fingers.

## Playing styles

A playing style answers two questions: how many fingers count, and how many holes one finger
covers.

| Style | Fingers that count | Holes per finger |
|---|---|---|
| Many fingers, many notes (the default) | Every finger | Every hole the finger's contact overlaps |
| Many fingers, one note | Every finger | The hole under the finger |
| One finger, many notes | The topmost finger | Every hole its contact overlaps |

One finger taking one note would be an instrument that plays no chords, so it is not offered.
Switching style silences what is sounding. The menu names each style as a full sentence, and the
button shows the chosen style's name exactly as the menu lists it. How wide a contact is depends
on the platform: the iPhone measures the finger, and the page asks for a number of notes.

## Shaping the tone

**The square's vertical axis rests in the middle.** Down bends and up overbends, which mirrors the
mouth: a bend tunes the mouth's resonance below the sounding reed, an overbend tunes it above, and
the two are opposite adjustments on one continuum. On any hole and breath exactly one half is
live, and the other half's label dims. The live label names the technique this reed offers:
`overblow ↑` on holes 1 to 6 blown and `overdraw ↑` on holes 7 to 10 drawn, `bend ↓` where the
reed bends, and `overbend ↑` when nothing is sounding.

The axis is read against the reed sounding now, not an absolute mouth shape: a bend is always the
same move relative to the pitch under it, so one rule covers the whole instrument. Each half has
half the travel, and pinching the square larger gives more.

**A bend is continuous, an overbend pops.** The lower half pulls the reed down smoothly, up to its
own range. The upper half does nothing until half its travel and then gives the whole overbend,
because an overblow does not slide in on the instrument: it pops once the reed goes over. The
reed that was sounding dies while the other one catches, over a 50 ms crossfade, so the pitch
never passes through the notes in between. The threshold is also a deadband, so a thumb resting
near the middle does not flicker between plain and overbent. Travel above the threshold does
nothing more.

**A chord bends as a chord.** One vocal tract pulls every sounding reed by the same amount, so the
shallowest chamber sets how far the whole chord bends. An overbend shifts each sounding reed by
its own range instead, because each chamber lands where its own two reeds put it.

**Vibrato** runs from none at the left of the square to full depth at the right. Lifting the
finger out of the square returns pitch and vibrato to rest. When the sounding reed cannot bend the
bend label dims. The vibrato label never does, because vibrato works on every reed.

**The square's size** is its natural side, the smaller of the screen's height and 22 per cent of
its width, times whatever the pinch chose. Two fingers in the square are a pinch and stop
shaping, while two fingers on the strip are always a chord. On the page the size is not remembered
between launches. The iPhone keeps it with the other settings.

## What the screen shows

**The note row.** Above each plate, a sounding hole names its note, rounded to the nearest
semitone, and beneath it, when something shifted the pitch, the reed it started from and what
shifted it: `C♯5` over `(D5 bend)`, `(G4 overblow)`. A silent hole shows nothing, so the row is as
quiet as the playing. The key is not an effect, so the bracket names the reed in the current key.
Vibrato is not an effect either, since it swings around the reed rather than moving it to another
note.

**A sounding plate lights the half that is sounding**, the top for blow and the bottom for draw,
so a tune shows where to put a finger and which way to breathe.

**Finger circles** mark every finger on the strip that is playing, drawn as wide as the holes the
finger covers where width counts. The finger that decides the breath is marked apart from the
others.

## Tunes

The tune menu holds seven pieces, played through the instrument itself: the plates light, the
note row names each note, and a bend is a fraction of that reed's own range, exactly as when a
finger plays.

| Tune | What it plays |
|---|---|
| Blues strain | Twelve bars in G, second position: train chug, the I, IV and V chords, the bent third draw, a shake in the upper fill, the hole 6 overblow |
| Slow drag | Scoops and released bends, long notes under vibrato, a slide into a phrase, one shake |
| Hammer song | Chugging blow and draw, tongue-block octaves on holes 1 and 4, tongue slaps, syncopation |
| Fox chase | A gallop chug, shakes, deep bends released and horn chords, in the genre's uneven bars |
| Nese Halia vodu | Ukrainian folk, in A, third position on a harmonica in G |
| Oi pid vyshneiu | Ukrainian folk, in D, third position on a harmonica in C |
| Na Ivana na Kupala | Ukrainian folk, in G, first position on a harmonica in G |

The first four are settings written in the idiom, not transcriptions of any recording or
published tab, and each puts one group of techniques on the instrument. The three Ukrainian songs
are melodies to play along with: single notes, no bends or overbends, all inside holes 4 to 6, in
keys and positions chosen so that a mouth can take every one of them. They are folk songs with no
author, written as they are commonly sung.

**A tune names the key it sounds in and the position it is played in**, and the key slider moves
to the harmonica it needs when it starts.

**How a tune is played.**

- A note names holes, not a hole, because a mouth covers two to four of them: chords carry the
  rhythm and single notes the melody. Every hole sounds on the note's breath, at the pressure the note names, and at full pressure when it names none.
- A slide sounds every hole between where it starts and the note it arrives at, about 40 ms each,
  taken from the front of the arriving note.
- A shake rocks between two holes for the whole note, about every 60 ms, as fast as a mouth moves.
- A bend is written in semitones and becomes a fraction of the reed's own range. A scoop starts
  bent and lands plain, stepping every 10 ms so it glides rather than climbs in steps.
- Each note gives up to 50 ms of its end so the next one re-attacks, and a rest is only time.
- Every step is counted from the start of its note, so a note with many steps keeps its length.

**A finger takes over.** Touching the strip stops the tune, and the stopped tune leaves the
instrument as the finger has it: it does not end its note or ring the reeds down, since those are
the finger's reeds now. The stop button stops the tune and lets the reeds ring down. Notes are
placed by the platform's timer, whose jitter is a few milliseconds.
