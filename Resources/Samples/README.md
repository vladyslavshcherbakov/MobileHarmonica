# Samples

One WAV per distinct pitch of the harmonica, named for that pitch, as the library ships them:
`hrmnca novbA2.wav`. The name's trailing note is the only part read. Everything before it is
ignored, so a different library's prefix needs no code change.

The labels of the Bolder Sounds harmonica in A read one octave below concert pitch, the
`C3 = middle C` convention that Kontakt and EXS24 use. `RecordedHarmonica` adds the octave
back through `semitonesAboveTheLabel`. A library labelled at concert pitch needs that constant
at zero, and the symptom of getting it wrong is every note an octave out.

The files here are cut to the four seconds the players read, and both platforms play them: the
app bundles the folder, and the page's build copies it and writes the index a browser needs in
place of a directory listing. They are a commercial library whose licence has not been read, so
whether they may be redistributed is unsettled. Replace them with recordings you hold the rights
to before shipping the app. Without them the app says sound is unavailable.
