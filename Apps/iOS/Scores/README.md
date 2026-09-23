# Scores

A score is a text file with the extension `.score`. The app reads the first one it finds here at
launch and adds it to the tune menu, ahead of the seven built-in tunes.

These files are not committed: what you write here is yours and its rights are yours.

```
key D              # the key the music sounds in, not the harmonica
position second    # first, second or third
tempo 130          # beats per minute, where one beat is a length of 1

D5 1               # a note, then how many beats it lasts
F5 0.5
- 0.5              # a rest
D5+F5+A5 2         # a chord, played by covering those holes at once
```

Pitches are spelled `C4`, `C#4` or `Db4`, from `C` to `B`, with the octave where middle C is
`C4`. Anything after a `#` on a line is ignored.

The reader turns each pitch into a hole, a breath and, when it has to, a bend or an overbend.
It prefers a plain note to a bend and a bend to an overbend, and among equal choices it takes
the hole nearest the one before, so the mouth moves as little as it can.

It then logs what the harmonica made of the piece: how many bends and overbends it needed, the
widest leap in holes, and any note it could not reach at all. A leap of more than three or four
holes is one no mouth makes at speed, and an unreachable note is one this harmonica does not
have in this key. Move the key or the position and read the line again.
