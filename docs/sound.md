# Sound

How sounding reeds become audio: the voices, how a reed speaks and stops, the recordings, the
mix, the bend and the overbend, the cupped hands and the vibrato. Both platforms follow these
rules with the same numbers. How each one plays them is in [docs/ios/sound.md](ios/sound.md) and
[docs/web/sound.md](web/sound.md).

## Contents

1. [Voices](#voices)
2. [Speaking and stopping](#speaking-and-stopping)
3. [The recordings](#the-recordings)
4. [The mix](#the-mix)
5. [Bend and overbend](#bend-and-overbend)
6. [Cupped hands](#cupped-hands)
7. [Vibrato](#vibrato)

## Voices

Each sounding reed is a voice: a recorded note read at the speed that gives the wanted pitch,
with its own loudness and the semitones it can bend. The set of sounding reeds changes when a
hole, a breath or an overbend changes. Breath intensity, bend, vibrato and the cup change on
every movement of a finger, and only their latest value counts.

## Speaking and stopping

**A reed speaks in 5 ms**, whatever else is happening, which is how long a real reed takes, and the
recording carries its own attack on top.

**A reed that is no longer wanted fades at the pace of the change.** Moving to another hole or
turning the breath fades it over 20 ms, enough to remove any click and short enough that a fast
run stays clean. An overbend engaging or releasing fades it over 50 ms, since one reed really does
hand over to another. Because a new reed is at full volume after 5 ms while the old one is still
fading, both sound together for a moment on a slide, as they do under a mouth dragged along the
instrument.

**Letting go and being stopped sound different.**

| What happened | What the reed does |
|---|---|
| The finger lifts, or the stop button ends a tune: the mouth comes off | It rings down on its own, exponentially, over about thirty cycles of its pitch: 29 ms at C6, 68 ms at A4, 115 ms at C4 |
| Something stops it: the tongue in a chug, the mouth moving on, the air reversing | It is damped and gone in 20 ms |

A reed's ring is a count of cycles rather than a length of time, because its damping scales with
its frequency. Thirty cycles is a well set-up instrument, which damps harder than a leaky one.

**A note taken again speaks again.** A reed that is still wanted keeps sounding, because the mouth
never left its hole. A reed that is fading is never revived: taking its note again starts a new
voice from the recorded attack while the old one finishes fading, so a fast repeat on one hole
is heard as separate notes.

**Turning the breath makes every reed speak again**, because every reed stops when the air
reverses. That holds even for a pitch both breaths share, such as G4 on a C harmonica, hole 3
blown and hole 2 drawn.

## The recordings

**One recording per pitch**, loaded once when the sound is prepared, mixed to mono and kept in
memory, so nothing is streamed or decoded while the instrument plays. The library is a harmonica
in A: 19 pitches from A2 to A6, 24-bit mono at 44.1 kHz.

**Every note is read from the nearest recording**, nearest in octaves rather than hertz, and read
faster or slower to reach its pitch, which moves its formants as a bent reed does. Inside A3 to
A6 every chromatic pitch is within a semitone of a recording. Above A6 there is none, so the top
holes of the higher keys are stretched further: three semitones on hole 10 in C, five in D and
nine in F♯.

The library labels its files an octave below concert pitch, and the octave is added back when
they are read: hole 4 blown on a C harmonica sounds C5.

**A note plays its recorded attack, then loops seconds 1 to 4 of its recording** for as long as it
is held. The files are cut to those four seconds. A recording too short to hold the loop is
refused and named.

**The loop's end is blended into its start** over 150 ms of equal power when the file is read, so
the wrap is an ordinary step in the waveform with no click, and the reed's slow decay across the
loop glides back rather than jumping by up to 2.3 dB. 150 ms is sixteen periods of the lowest
recording, enough that the two copies do not comb, and a twentieth of the loop, little enough
that the recording's expression is kept.

## The mix

**One breath is enough for up to four reeds.** The voices are summed and scaled only by the
breath, so a chord is louder than one note, as it is on the instrument. Past four sounding reeds
the sum is divided down, so a hand covering all ten holes is held at the loudness of four.

That bound keeps the output from clipping: four reeds at full scale and perfectly in phase reach
exactly full scale at the output level of a quarter, and real recordings at different pitches
never align, so the headroom is never spent.

## Bend and overbend

**A bend** lowers every sounding reed by the same fraction of the shallowest range among them,
since one mouth pulls a whole chord and the chamber that runs out first sets the limit. It is one
multiplication of each voice's speed.

**An overbend is a different reed**, not a bent one: the overbent pitch sounds as a new voice with
the 50 ms crossfade, exactly like moving to another hole, and an overblow cannot be bent further.

## Cupped hands

**Closing the hands darkens the sound** without changing its pitch, as a cavity around the
instrument takes off the high partials. It is one low-pass filter on the mix whose cutoff sweeps
from 20 kHz with the hands open, where nothing is audibly touched, down to 800 Hz with them shut,
which keeps every fundamental and takes the harmonics off. High notes are muffled harder than low
ones, as they are behind a real cup of fixed size.

The filter has no resonance. A resonant cup would make a wah a vowel, but normalising its peak
makes closing the hands mostly drop the level, which sounds like the harmonica going quiet rather
than speaking.

## Vibrato

**Vibrato is mostly loudness.** One shared wave near 5.5 Hz moves the pitch by 1.5 per cent,
about 26 cents either way, and dips the loudness by up to a quarter. Pitch alone at that depth
sounds like a siren rather than a player. The loudness only dips, so vibrato never spends the
mix's headroom.

**Its rate and depth breathe.** A slower wave at 0.23 Hz moves the rate by eight per cent and the
depth by a fifth, against each other: faster is shallower and slower is deeper. It is a wave
rather than chance, so the same phrase played twice sounds the same twice.
