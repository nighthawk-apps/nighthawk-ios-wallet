# DarkIRC testing rule

Live and manual DarkIRC tests use **`#random`**.

`#dev` is the development meeting channel. Do not post test traffic there, or in `#memes`, `#philosophy`, or any other public channel.

- Smoke posts, sync checks, and desktop ↔ Android ↔ iOS message checks go to `#random` only.
- Clients autojoin `#nighthawk` first, then the upstream channel list. Join and send on `#random` for the test (not `#nighthawk` or `#dev`).
- A message counts only if the other client shows that same `#random` post (UI, logcat, or the darkirc log). A send to another channel is not a pass.
