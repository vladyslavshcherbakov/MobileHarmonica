# Sound on the page

How the page plays [the product's sound](../sound.md): where the recordings come from, how the
sound starts, and how it plays alongside the rest of the phone. The voices, crossfades, vibrato
and cup use the same numbers as the phone.

## The recordings

The page fetches the same recordings the app carries, published beside the page with an index of
their names, and decodes them when the sound is prepared. Until they arrive the page is silent,
and if they cannot be loaded the screen says sound is unavailable, as the app does.

## Starting the sound

**Sound starts with a tap.** A browser starts audio only inside a gesture, so the page opens on a
**tap to play** button. It reads **loading the instrument** and refuses the tap until the core has
been fetched and compiled, since nothing could answer the tap before that.

**The sound plays through one audio worklet** that owns every voice and renders in blocks of 128
frames, the size Web Audio uses. The page asks the browser for its lowest-latency setting and
logs the latency it got.

## Alongside the phone

**Sound plays over the silent switch** in Safari, which otherwise treats a page's audio as
ambient and mutes it with the switch.
