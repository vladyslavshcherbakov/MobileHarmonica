# Sound on the iPhone

How the app plays [the product's sound](../sound.md): the output, the recordings it carries, and
what happens when something else takes the audio.

## The output

**The shortest buffer the phone allows.** The app plays through a Remote I/O audio unit and asks
the audio session for a 1 ms buffer, which iOS rounds to what the hardware can do. The session
plays in `.measurement` mode, which leaves out the system's own processing of the output. The log names what the phone granted: the sample rate, the buffer in
frames and milliseconds, and the latency to the speaker.

**Sound plays over the silent switch**, since the instrument's sound is the point of the app.

## The recordings

The app carries the recordings in its bundle, from `Resources/Samples/`, and reads them when the
sound is prepared. Without them the screen says sound is unavailable, and says which recording
could not be read if one is broken.

## Interruptions

**A call or an alarm stops the output**, and while it lasts touches are not sounded. When it
ends the session is reactivated, anything that was sounding is silenced and the output restarts.
A reset of the system's media services rebuilds the output.
