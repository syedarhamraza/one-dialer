# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

Android owners (Android 10+, any brand) who want a better default phone app than the one their phone shipped with. All of these are primary, not one over the others:

- Everyday users replacing a stock dialer with a nicer, private one.
- People who want the ColorOS 17 / vivo look and motion on other phones (Samsung, Pixel, ...).
- Tech-savvy enthusiasts in the Google Play closed test who tolerate rough edges and send feedback.

The job is the phone itself: answer and place calls (often one-handed, on the lock screen, in a hurry), find a contact or number fast, check who called, and block unwanted callers.

## Product Purpose

One Dialer is a full default phone app: dial pad, call history, contacts, the call screen, blocking and settings. It exists because most phones ship a dialer you can't change, and most replacements look dated or want an account. Success is a dialer people keep as their default: calls never misbehave, and it looks and moves like a modern phone skin.

## Positioning

All four together are the difference; future work keeps every one:

1. **A real Telecom dialer.** Every call goes through Android's own Telecom framework (InCallService, call screening role), so calls behave exactly like the system dialer's. Reliability of the call path outranks any visual.
2. **Private by design.** No ads, no accounts, no servers; contacts and call logs stay on the phone. The mic is untouched unless the separate, sideloaded One Recorder companion is installed.
3. **ColorOS 17 look and motion.** Frosted call glass, spring motion, squircle corners, tuned per phone chip (Reduce visual effects: Full / Reduced / Off, defaulted from the GPU tier) so it stays smooth on budget phones.
4. **Open source.** GPL-3.0, public repo, community translations.

## Operating Context

- Ringing calls arrive over the lock screen and from the background (full-screen notification, vivo Origin Island card, Android 16 Live Update).
- In-call use is glanceable and urgent: answer/decline, mute, speaker, hold, keypad, merge.
- Dual-SIM is common (per-contact SIM, "ask every time").
- Distributed through Google Play closed testing; the companion recorder through GitHub Releases. Website at `site/` (privacy policy, release notes).

## Capabilities and Constraints

- Flutter UI over a Kotlin Telecom layer; two Flutter engines (main app, pre-warmed in-call engine).
- Designed at 420 dp wide and scaled to the screen; no per-device breakpoints.
- Performance is a product constraint: lazy lists, few backdrop reads, everything new honours Reduce visual effects and the separate Call screen effects.
- Light, dark and system theme; Glass style: Edge glow or Liquid glass (Full effects only).
- English and Italian; no user-facing literal outside the l10n files.
- Call recording only through One Recorder; recording laws differ by country.
- Never real names, numbers or call logs in code, tests or screenshots.

## Brand Commitments

- Name: **One Dialer** (companion: **One Recorder**). Sibling app: OneSpend, the origin of the floating chrome.
- Design language is ColorOS 17, not Samsung One UI; One UI leftovers convert when touched.
- One launcher icon, drawn from the app's own glyphs, never traced from another OS.
- Voice (README, site): plain, direct, short sentences; states what it does and doesn't do.

## Evidence on Hand

- Screenshots: `docs/screenshots/01-glass-design.webp` ... `08-make-it-yours.webp`.
- Icon: `docs/play-icon.png`, `assets/app_icons/default_phone.png`.
- Changelog: `lib/core/config/changelog.dart`, `site/public/changelog.json`.
- Privacy policy: `docs/privacy-policy.md`.
- No testimonials, ratings, install counts or press exist; don't invent them.

## Product Principles

1. Calls first: nothing visual may risk a missed, dropped or misrouted call.
2. Nothing leaves the phone.
3. Smooth on every phone: effects scale down before frames drop.
4. Behave like the system: platform roles, block list, contact screens and notifications, not private re-implementations.
5. Open and translatable.

## Accessibility & Inclusion

Not decided yet: no formal standard (platform baseline vs WCAG 2.2 AA) has been chosen. Existing commitments: Reduce visual effects, reduced-motion support on the keypad sheet, localisation.
