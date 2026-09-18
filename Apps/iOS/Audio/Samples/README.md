# Samples

One WAV per distinct pitch of the harmonica, named for that pitch, as the library ships them:
`hrmnca novbA2.wav`. The name's trailing note is the only part read; everything before it is
ignored, so a different library's prefix needs no code change.

The labels of the Bolder Sounds harmonica in A read one octave below concert pitch, the
`C3 = middle C` convention that Kontakt and EXS24 use. `RecordedHarmonica` adds the octave
back through `semitonesAboveTheLabel`. A library labelled at concert pitch needs that constant
at zero, and the symptom of getting it wrong is every note an octave out.

The WAV files are not committed. They are a commercial library and the licence has not been
read, so the folder ships empty and the app says sound is unavailable until they are copied in.
