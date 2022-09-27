# Steam setup apps

## Alfred

Application with utilities for streaming on Twitch, these application has some components

### Overlay

This is a liveview page in `/overlay` which can be loaded in OBS using web browser source

We can connect Emacs with this overlay by using [streaming-mode](../emacs/streaming-mode.el)

### Chat bot and commands

Using Twitch IRC server we can listen to messages and define handler for commands

### Cheapdeck

Use a regular numeric keyboard to control obs through websockets

### Emacs integration

Emacs is connected with `alfred` through websockets
