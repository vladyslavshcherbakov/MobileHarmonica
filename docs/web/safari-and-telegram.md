# Safari and Telegram

How the page runs as an instrument inside a browser: installing to the home screen, filling the
screen, and running as a Telegram mini app.

## Installing and filling the screen

**The page installs as an app.** Added to an iPhone's home screen, it starts full screen in
landscape with no browser around it. Safari on iPhone cannot fill the screen from a tab, so the
start screen advises installing wherever that is the only way, and only there: never on a
desktop and never when the page is already running from the home screen.

**A button fills the screen** where the browser can, and is hidden where it cannot. If the
browser refuses, a note explains how to add the page to the home screen instead, with the
browser's own reason.

**Filling the screen and starting the sound are two taps.** Entering full screen uses up the tap
a browser requires before it starts audio, so the sound needs a tap of its own.

## Inside Telegram

**The mini app is the same page.** A Telegram bot points at the published address, and the page
adapts to Telegram's window when it is opened there.

- The vertical swipe that would close the mini app is turned off, because a vertical drag is how
  the instrument breathes.
- The window asks for full screen, since it opens as a portrait sheet.
- The window may follow the phone into landscape, and locks there once it is landscape, so a turn
  of the wrist mid-phrase cannot take the instrument away.
- The key bar keeps clear of Telegram's own controls.

Each of these needs Bot API 7.7 or 8.0, and a client without it is left as it is, with a line in
the log naming what was missing. Opened in a browser, the page loads nothing from Telegram.
