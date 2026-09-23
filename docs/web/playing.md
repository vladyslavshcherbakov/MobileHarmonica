# Playing on the page

What the page does differently from the phone in how it is played and what it shows. Everything
not named here follows [the product's rules](../playing.md).

## How many notes a finger takes

**A menu sets it.** A browser does not report how wide a touch is, so instead of measuring a
finger the page asks for the width: `1 note` to `4 notes` in the top bar. A finger then covers
the holes whose centres fall inside a span that many holes wide, so four notes is four holes, and
a span at the end of the strip hangs over the edge as a mouth does. At one note the finger takes
the hole it is over. The page starts at one note.

On the style that gives each finger one hole, the menu shows `1 note` and is disabled. The number
chosen is kept, so returning to a style that spans several notes brings it back.

## Notes by pressure, on a Mac

**Safari on a Mac adds a fourth style, `One finger, notes by pressure`**, where pressing the
trackpad harder spreads one finger across more holes. Safari on a Mac is the only browser that
reports how hard a trackpad is pressed, so everywhere else the menu keeps its three styles.

| Press | Width | What sounds |
|---|---|---|
| A click | none | The hole under the pointer |
| Just past a click | a sliver | Two holes when the pointer is near a boundary |
| A force click | 0.81 holes | One hole at a hole's centre, two near a boundary |
| About 2.2 and firmer | past one hole | Three holes at a hole's centre |
| The firmest press | 1.9 holes | Three at a centre, two across a boundary, never four |

The width grows evenly with the press and follows the phone's rule that every hole the circle
touches sounds. The circle on the strip is drawn at that width, and never smaller than a finger
at rest. The notes menu shows `by pressure` and is disabled while this style is on, and leaving
it brings back the number of notes chosen before. A force click does not open Look Up.

## What the page does not have

**No cupped hands.** A browser gives the phone's lean only after asking permission, which Safari
and Telegram do not grant in a way the page can use, so the hands never close on the page and the
top bar has no control for them.

**No written scores.** The page plays the eight built-in tunes, the same notes the phone plays.

## The screen

**It fills the visible area in either landscape** and never scrolls or rubber-bands. In portrait
the page asks to turn the phone. Only the square extends under the notch. The strip stays clear
of it and of the home indicator.

**The top bar keeps every control reachable.** Controls shrink to fit, the bar scrolls sideways
if even that is not enough, and the button that fills the screen sits first, where nothing can
push it off.

**A note name shrinks to fit its hole**, down to 0.6 of its size, and what is still too long is
clipped, as on the phone.

**Touches are per surface.** The strip and the square each see only their own fingers. A mouse
plays as one finger. Two fingers in the square are a pinch and stop shaping the tone.
