---
name: One Dialer
description: A private Android phone app in ColorOS 17's frosted glass, over pitch black.
colors:
  call-green: "#00C216"
  dial-green: "#5BB450"
  phone-green: "#00C05A"
  action-blue: "#5390F5"
  alert-coral: "#F07167"
  pitch-black: "#000000"
  charcoal-card: "#1C1C1E"
  charcoal-card-raised: "#262628"
  charcoal-pill: "#2C2C2E"
  charcoal-pill-active: "#3E3E42"
  smoke-glass: "#222226B3"
  smoke-modal: "#202024C4"
  text-white: "#FFFFFF"
  text-ash: "#9E9EA4"
  text-graphite: "#6A6A70"
  section-mist: "#D4D4D8"
  hairline-dark: "#FFFFFF1A"
  light-page: "#F2F3F5"
  light-page-flat: "#E9E9EE"
  light-card: "#FFFFFF"
  light-pill: "#F5F5F8"
  light-text: "#000000"
  light-text-secondary: "#5E5E63"
  light-text-tertiary: "#8E8E93"
  light-glass: "#FFFFFFE6"
  light-modal: "#FFFFFFF2"
  hairline-light: "#0000001A"
typography:
  display:
    fontFamily: "sans-serif (the phone's own system font)"
    fontSize: "34dp"
    fontWeight: 700
    letterSpacing: "-0.5"
  headline:
    fontFamily: "sans-serif"
    fontSize: "22dp"
    fontWeight: 600
    letterSpacing: "-0.3"
  title:
    fontFamily: "sans-serif"
    fontSize: "17dp"
    fontWeight: 400
    lineHeight: 1.25
  body:
    fontFamily: "sans-serif"
    fontSize: "16dp"
    fontWeight: 500
    letterSpacing: "-0.2"
  label:
    fontFamily: "sans-serif"
    fontSize: "15dp"
    fontWeight: 400
  caption:
    fontFamily: "sans-serif"
    fontSize: "13.5dp"
    fontWeight: 400
    lineHeight: 1.25
rounded:
  badge: "16dp"
  inner: "20dp"
  card: "26dp"
  pill: "34dp"
  round: "999dp"
spacing:
  hairline: "1dp"
  bar-gap: "8dp"
  row-x: "18dp"
  row-y: "17dp"
  card-gap: "20dp"
components:
  button-call:
    backgroundColor: "{colors.call-green}"
    textColor: "{colors.text-white}"
    rounded: "{rounded.round}"
    height: "54dp"
  button-dialpad:
    backgroundColor: "{colors.dial-green}"
    textColor: "{colors.text-white}"
    rounded: "{rounded.round}"
  glass-pill:
    backgroundColor: "{colors.smoke-glass}"
    textColor: "{colors.text-white}"
    rounded: "{rounded.round}"
  nav-bar:
    backgroundColor: "{colors.smoke-glass}"
    textColor: "{colors.section-mist}"
    rounded: "{rounded.round}"
    height: "58dp"
  nav-bar-active:
    backgroundColor: "{colors.charcoal-pill-active}"
    textColor: "{colors.text-white}"
  group-card:
    backgroundColor: "{colors.charcoal-card}"
    textColor: "{colors.text-white}"
    rounded: "{rounded.card}"
    padding: "17dp 18dp"
  group-card-light:
    backgroundColor: "{colors.light-card}"
    textColor: "{colors.light-text}"
    rounded: "{rounded.card}"
  modal:
    backgroundColor: "{colors.smoke-modal}"
    textColor: "{colors.text-white}"
    rounded: "{rounded.card}"
  search-pill:
    backgroundColor: "{colors.smoke-glass}"
    textColor: "{colors.text-ash}"
    rounded: "{rounded.pill}"
---

# Design System: One Dialer

## Overview

**Creative North Star: "Frosted Night Glass"**

A pitch-black page with frosted call glass floating over it, light caught along its edges. Content (call history, contacts, settings) sits flat on the black in dense, quiet rows and grey cards; every control the hand reaches for (nav bar, header pills, keypad keys, menus, call controls) is a floating pane of glass that blurs what scrolls beneath it and glows where it's touched. Green is lit, not painted: the Call button is the one surface that emits light.

The design language is ColorOS 17, ported from a Samsung One UI base (the sibling app OneSpend). One UI leftovers (coloured icons, One UI dialogs and fields) convert to the ColorOS 17 look when touched. Controls feel soft and springy: they squeeze, stretch toward the finger and glow on press, and every morph runs on a spring rather than a linear tween.

Everything is designed at 420 dp wide and scaled to the screen, and the whole look degrades by device tier: Full (call glass, progressive header blur, optional Liquid glass), Reduced (One UI's flat translucent fill over one shared blur) and Off (solid fills, no blur). The degraded tiers keep the original flat look; they never imitate the glass.

**Key Characteristics:**
- OLED pitch-black ground in dark mode; ColorOS 17 grey page with white cards in light mode.
- Floating frosted glass for every control; flat cards for content.
- Squircle corners on rectangles; circles and stadium pills stay exactly round.
- One lit green action per screen; colour is otherwise rare.
- Springs, squeeze and glow on press; reduced motion honoured.
- The phone's own system font, so OEM font themes carry through.

## Colors

A near-monochrome charcoal-on-black world where green means "call" and almost nothing else is coloured.

### Primary
- **Call Green** (call-green): ColorOS's vivid flat green, the keypad's Call button and the lit `GlowButton`. Drawn with a thin rim (white on top, brighter green beneath), a soft green shadow and a green press glow.
- **Dial Green** (dial-green): the softer green of the round dialpad button beside the nav bar.
- **Phone Green** (phone-green): the brand green: launcher icon, Play badges, the website, answer affordances.

### Secondary
- **Action Blue** (action-blue): text actions and selected controls (switch, "Add", search matches, the keypad's T9 highlights). Never a fill for large surfaces.

### Tertiary
- **Alert Coral** (alert-coral): destructive and warning states (delete, block warnings, missed-call red). The call screen's Decline/Hang up red lives with the call controls.

### Neutral
- **Pitch Black** (pitch-black): the dark page. Pure black, for OLED.
- **Charcoal Card / Raised** (charcoal-card, charcoal-card-raised): grouped-row cards and their pressed/highlighted state.
- **Charcoal Pill / Active** (charcoal-pill, charcoal-pill-active): inset pills, the nav bar's selected tab.
- **Smoke Glass** (smoke-glass, ~70% charcoal): the flat floating fill below Full effects; **Smoke Modal** (smoke-modal) is denser so long sheet content stays legible.
- **White / Ash / Graphite** (text-white, text-ash, text-graphite): primary, secondary (values, subtitles, card headers) and tertiary text. **Section Mist** (section-mist) for section headers and inactive nav icons.
- **Light mode** (light-*): grey page (#F2F3F5 at Full, darker #E9E9EE below it so shadowless pills still stand out), white cards, black text, near-white glass with ColorOS 17's two-layer haze shadow.

### Named Rules
**The Lit Green Rule.** Green is light, not paint: only the call action glows green, and at most one green button is lit per screen.

**The Glass Stays Dark Rule.** Floating glass keeps its dark constants in both themes unless a light-mode variant exists (`lightFloating`, `lightModal`); read page colours through `context.palette`, never hard-code them.

## Typography

**All roles:** `sans-serif`, the phone's own system font (vivo's, ColorOS's, Roboto on Pixel). Bundled Roboto Bold is used only for the glass version numeral.

**Character:** Native and neutral; hierarchy comes from size and weight with slightly tightened tracking, never from a brand typeface.

### Hierarchy
- **Display** (700, 34 dp, −0.5): the Calls and Contacts big titles, which hand over to the headline as they scroll under the header.
- **Headline** (600, 22 dp, −0.3): the small header title and pushed pages' titles (18 dp when centred).
- **Title** (400, 17 dp, 1.25): a group-card row's label; contact and call rows.
- **Body** (500, 16 dp, −0.2): header controls, emphasised text.
- **Label** (400, 15 dp): row values, card headers (in Ash), menu items.
- **Caption** (400, 13.5 dp, 1.25): row subtitles.

### Named Rules
**The System Font Rule.** Never name a font family for UI text; 'sans-serif' lets OEM font themes through, where 'Roboto' would ignore them.

## Layout

The app is laid out at a 420 dp design width (the vivo it was tuned on) and scaled to the screen: down on 360 dp phones, up to 1.15× on wide phones and tablets, landscape unscaled. No per-device breakpoints. Settings › Display size scales pages, and the nav bar and header buttons keep their own size.

- Header bar: 60 dp under the status bar, round glass buttons at either end, a ColorOS 17 progressive header blur behind.
- Floating nav bar: 58 dp, 8 dp above the safe area; all bottom bars share that baseline. Lists pad with `navBarClearance()` so content clears it.
- Group cards: 18 dp row inset, 17 dp row padding, 20 dp between cards, card headers 18 dp in.
- Lists are lazy slivers with fixed-extent rows; row structure is identical in and out of selection mode.
- Every page bounces at its ends (softened iOS bounce); fitted panels, the keypad sheet and the call screen hold still.

## Elevation & Depth

Depth is material, not shadow: content is flat on the page, and anything that floats is glass that blurs the content behind it. In dark mode shadows are minimal (a 30% black, 14 dp blur under floating pills; 35% black, 16 dp, lifted upward under the nav bar; none on cards). In light mode ColorOS 17's haze lifts glass off the white: a wide faint shadow plus a tight edge shadow, deeper for menus.

At Full effects the glass is the call glass: backdrop blur (σ 20), a milky wash, an all-round edge glow and a bright top lip, drawn from a cached image on the keypad keys. Glass style › Liquid glass swaps floating bodies for refractive liquid glass, as far as the user's chosen scope reaches.

### Named Rules
**The One Backdrop Rule.** Blurs on a page share one backdrop read (`BackdropFilter.grouped` under the page's group); a new blur layer is a cost, not a flourish. Never put glass under an animated `Transform`.

**The Honest Tiers Rule.** Reduced and Off are the original flat One UI look; they never fake glass with gradients or glows.

## Shapes

Rounded rectangles are ColorOS 17 squircles (`SquircleBorder`, a smooth superellipse); any shape whose corners reach half its short side is drawn as an exact circle or stadium, so pills and round buttons never flatten. Radii: badges 16 dp, inner panels 20 dp, cards and modals 26 dp, fields and pills 34 dp, round controls fully round. No borders on cards; hairline dividers (10% white or black, 0.8 dp) separate rows.

## Components

### Buttons
Soft and springy glass that squeezes, stretches toward the finger and glows on press (`PressGlow`).
- **Call (lit):** fully round Call Green, 54 dp tall (`GlowButton`), rim light, soft green shadow, green press glow. While busy, a band of light sweeps across it every 1.4 s (still under reduced motion).
- **Dialpad:** round Dial Green button beside the nav bar when the keypad sheet is hidden.
- **Glass round buttons / header pills:** call glass circles and stadiums; icons in white.
- **Unlit big button:** the same `GlowButton` in call glass.

### Cards / Containers
- **Group card** (`OneUIGroupCard`): flat charcoal (white in light mode) squircle, 26 dp; rows with a grey value and a chevron; a grey header above the card.
- **Floating modal and menu:** glass at modal density, 26 dp squircle; the menu grows out of its button on a spring.

### Inputs / Fields
- **Search pill:** a floating glass stadium with Ash placeholder text.
- **Keypad number:** an editable field that never opens the soft keyboard, grouped as you type.

### Navigation
- **Floating nav bar:** a 58 dp glass stadium; the selected tab sits on the active charcoal pill in white, inactive tabs in Section Mist. In selection mode it morphs into the selection actions. With Liquid glass it becomes the glass package's tab bar.
- **Header:** big title on the page that collapses into a 22 dp header title; selection mode shows the count pill and cancel pill.
- **Pushed pages:** round glass Back button and title over the header blur (`OneUISubpage`).

### Keypad Sheet (signature)
A frosted, rounded sheet with a drag handle and call-glass stadium keys, over the Calls list; bottom row dialpad | Call | delete. With nothing typed it draws no backdrop; while typing, the number takes the header's place.

### Call Screen (signature)
A caller-tinted gradient aurora behind ColorOS 17 controls with the glass package's motion; its own effects setting (Call screen effects) and its own glass. See `docs/call-screens.md`.

## Do's and Don'ts

### Do:
- **Do** use `SquircleBorder` (or `OneUITheme.cardShape`) for every rounded rectangle.
- **Do** route new glass and blurs through `OneUIEffectsController` (`isFull`, `isOff`, `oneUIFill`) so they follow Reduce visual effects.
- **Do** read page colours through `context.palette` so light mode works.
- **Do** press buttons with `PressGlow` and animate morphs with springs (stiffness ~240–320, damping ratio ~0.6–0.85).
- **Do** copy OneSpend widgets verbatim, swapping only their corners to squircles and labels to `context.l10n`.
- **Do** draw icons from the app's own glyphs.

### Don't:
- **Don't** add new full-width `BackdropFilter` or `ShaderMask` layers.
- **Don't** put glass under an animated `Transform`, or a mask blur in a press glow.
- **Don't** show glass cues (glow, wash, liquid) at Reduced or Off effects.
- **Don't** use One UI coloured icons, One UI dialogs or fields in new work; use the ColorOS 17 forms.
- **Don't** name a font family for UI text.
- **Don't** trace icons or artwork from another OS.
- **Don't** light more than one green action on a screen.
