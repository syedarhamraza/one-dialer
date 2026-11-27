<p align="center">
  <img src="docs/play-icon.png" width="112" alt="One Dialer icon">
</p>

<h1 align="center">One Dialer</h1>

<p align="center">
  A fast, private phone and contacts app for Android, in a frosted-glass ColorOS-style design.<br>
  Flutter on top, Android's own Telecom framework underneath. No ads, no accounts, no servers.
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.syedarhamraza.onedialer"><img src="docs/badges/google-play.svg" height="54" alt="Get it on Google Play"></a>&nbsp;
  <a href="https://github.com/syedarhamraza/one-dialer/releases/latest"><img src="docs/badges/github.svg" height="54" alt="Get One Recorder on GitHub"></a>&nbsp;
  <a href="https://discord.gg/yyKKr5nxbk"><img src="docs/badges/discord.svg" height="54" alt="Join us on Discord"></a>
</p>

<p align="center">
  <a href="https://play.google.com/store/apps/details?id=com.syedarhamraza.onedialer"><img alt="Google Play: open testing" src="https://img.shields.io/badge/Google%20Play-open%20testing-00C05A?logo=googleplay&logoColor=white"></a>
  <a href="https://github.com/syedarhamraza/one-dialer/releases"><img alt="Latest release" src="https://img.shields.io/github/v/release/syedarhamraza/one-dialer?include_prereleases&label=release&color=00C05A"></a>
  <a href="LICENSE"><img alt="License: GPL-3.0" src="https://img.shields.io/badge/license-GPL--3.0-blue"></a>
  <img alt="Android 10+" src="https://img.shields.io/badge/Android-10%2B-3DDC84?logo=android&logoColor=white">
</p>

<p align="center">
  <a href="https://syedarhamraza.github.io/one-dialer/">Website</a> ·
  <a href="https://syedarhamraza.github.io/one-dialer/privacy/">Privacy policy</a> ·
  <a href="CONTRIBUTING.md">Contributing</a> ·
  <a href="TRANSLATING.md">Translate</a>
</p>

<p align="center">
  <img src="docs/screenshots/calls.webp" width="24%" alt="Calls with the glass keypad">
  <img src="docs/screenshots/t9-search.webp" width="24%" alt="T9 search on the keypad">
  <img src="docs/screenshots/incoming.webp" width="24%" alt="Incoming call">
  <img src="docs/screenshots/in-call.webp" width="24%" alt="In call, with the caller's photo as the backdrop">
</p>
<p align="center">
  <img src="docs/screenshots/contacts.webp" width="24%" alt="Contacts with favourites and an A–Z index">
  <img src="docs/screenshots/dual-sim.webp" width="24%" alt="Choosing a SIM on a contact page">
  <img src="docs/screenshots/blocking.webp" width="24%" alt="Blocklist">
  <img src="docs/screenshots/glass.webp" width="24%" alt="Glass and blur settings">
</p>

## Why One Dialer

Most phones ship a dialer you can't change, and most replacements either look dated or want an account. One Dialer is a full **default phone app**: it answers, places and manages every call through Android's own Telecom framework, so calls behave exactly like the system dialer's, and it looks and moves like a modern phone skin. Everything stays on the phone.

## Features

### Calls and the call screen
- Incoming, outgoing and waiting calls: hold, swap, merge into a conference, mute, the in-call keypad, and speaker, earpiece, Bluetooth or wired headset routing.
- Video calls on your SIM, or through WhatsApp, Telegram, Meet and other apps. Each call shows video, Wi-Fi calling, VoLTE/VoNR and HD when they're on.
- A frosted call screen with spring motion. The backdrop is tinted by the caller, takes the colours of their photo, or uses a picture of your choice for everyone or per contact.
- Answer with two buttons or one swipe ball, and decline with a quick SMS reply (edit the list in Settings).
- Works on the lock screen. While unlocked, a call rings as a banner or opens the full call screen (your choice).
- **VIP calls** ring even when the phone is on Silent or Vibrate.
- Vibrate on connect and hang-up, speaker by default, auto-answer with a headset, and announce the caller's name.
- Call notes, written during or after a call and shown in your call history.
- **vivo Origin Island** shows a ringing and in-call card, and Android 16 phones can show the call as a Live Update.

### Calls tab and keypad
- Grouped call history (or one row per call), a missed-calls filter, search, and per-call details with notes.
- Tap, use the call button or swipe a row to call back, with the SIM you choose.
- Unsaved numbers show the caller's name from your carrier.
- A T9 keypad that finds contacts and recent numbers as you type, speed dial on keys 2–9, voicemail on 1, and hold-to-type `+`, pause and wait.
- Paste a number, place the cursor anywhere, and add it to a new or existing contact.

### Contacts
- Favourites, an A–Z index and search.
- Merge duplicates, import vCards, read SIM contacts, and see where each contact is stored.
- Choose which accounts to show, sorting, name order and the default save location.
- A default SIM per contact, plus "ask every time" for dual SIM.

### Blocking
- Android's system block list, so blocked numbers are rejected before they ring. Block a number, a prefix or a contact.
- Rules for private and unknown callers, run by Android's call screening.

### Make it yours
- Light, dark or system theme. **Glass & blur** lets you choose between Edge glow and Liquid glass.
- **Reduce visual effects** (Full, Reduced or Off) for the app and, separately, for the call screen. It defaults to what your phone's chip handles smoothly.
- Settings in sections, with search. **Back up & restore** your settings, with automatic backups.
- English, Italian, Russian, Spanish, Turkish and German, for One Dialer, One Recorder and the website ([add your language](TRANSLATING.md)).

### Call recording (optional)
Recording lives in a separate, sideloaded companion app, **One Recorder**. Install it from [GitHub Releases](https://github.com/syedarhamraza/one-dialer/releases/latest) and recording controls appear in the call screen and Settings. Without it, One Dialer never touches the microphone. Recording laws differ by country, so check yours first.

#### Legal notice
One Recorder is provided as is, without any warranty. It can record both sides of a call, and call recording laws differ by country and region: some places need everyone on the call to agree, and some don't allow recording at all. You alone are responsible for knowing and following the laws where you and the other person are, for telling them and getting their consent where it's required, and for how you use your recordings. Syed Arham Raza, who makes One Recorder and One Dialer, isn't responsible for how you use it or for any recording you make with it.

## Install

1. Install One Dialer from [Google Play](https://play.google.com/store/apps/details?id=com.syedarhamraza.onedialer). It's in open testing, so anyone can join from the store page.
2. Open it and tap **Set** to make it your default phone app. Calls only route through One Dialer once it's the default.
3. Optional: install **One Recorder** from [GitHub Releases](https://github.com/syedarhamraza/one-dialer/releases/latest) for call recording.

It needs Android 10 or newer.

## Community

- **[Discord](https://discord.gg/yyKKr5nxbk):** help, ideas, beta builds and release news.
- **[GitHub issues](https://github.com/syedarhamraza/one-dialer/issues/new/choose):** bug reports and feature requests.

## Privacy

No ads, no accounts and no servers of its own. Your call log, contacts and notes never leave the phone. The only data sent anywhere is crash and lag diagnostics (Firebase Crashlytics), which contain no numbers, names or call history. Details: [privacy policy](https://syedarhamraza.github.io/one-dialer/privacy/).

## Permissions

| Permission | Why |
|---|---|
| Phone, call log | Place and manage calls and show call history (required of a default dialer) |
| Contacts | Names, photos, search and editing |
| Notifications, full-screen intent | Ringing and ongoing-call notifications, and the call screen on the lock screen |
| Nearby devices (Bluetooth) | Route call audio to a headset |
| Call screening role (only if you turn on a blocking rule) | Reject private or unknown callers |

## How it's built

The UI is Flutter; a Kotlin layer talks to Android's Telecom framework (`InCallService`, call screening, the call log). Two Flutter engines share one call state: the main app, and a pre-warmed call screen that opens instantly, even on the lock screen. [AGENTS.md](AGENTS.md) is the full architecture guide.

## Contributing

Bug reports, translations and pull requests are welcome.

- **Translate the app:** follow [TRANSLATING.md](TRANSLATING.md). No coding needed.
- **Change the code:** start with [CONTRIBUTING.md](CONTRIBUTING.md). [AGENTS.md](AGENTS.md) is the architecture guide, for people and coding agents alike.
- **Found a security problem?** Report it privately as described in [SECURITY.md](SECURITY.md), not in an issue.

<!-- Hidden for now.
## Contributors

Thanks to everyone who has helped build One Dialer.

<a href="https://github.com/syedarhamraza/one-dialer/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=syedarhamraza/one-dialer" alt="One Dialer contributors" />
</a>
-->

## License

Copyright (C) 2026 Syed Arham Raza

One Dialer is free software under the [GNU General Public License v3.0](LICENSE). The "One Dialer" name, logo and icons are not covered by that license, so forks must use their own name and icons; see [TRADEMARK.md](TRADEMARK.md).
