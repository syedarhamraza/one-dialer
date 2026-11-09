# Security policy

One Dialer holds phone, call log and contacts permissions, so security reports are taken seriously.

## Reporting a vulnerability

**Please don't open a public issue.** Report it privately instead:

- through GitHub's [private vulnerability reporting](../../security/advisories/new) for this repository, or
- by email to arhamraza399@gmail.com with "One Dialer security" in the subject.

Include the app version (Settings › About), your phone model and Android version, and steps to reproduce. You'll get a reply within 7 days. Once a fix ships, you'll be credited in the release notes unless you'd rather not be.

## Supported versions

Only the latest release on Google Play and in this repository's current `beta/<n>` branch gets security fixes.

## Scope

In scope: the One Dialer app (`lib/`, `android/`) and the One Dialer Recorder companion (`companion/`). Examples: another app triggering calls or reading call data through One Dialer's exported components, or the companion trusting an app that isn't One Dialer.
