"""Renders the launcher icon, its preview (the website's icon), the Play Store icon and the vivo
island images from SVG.

The design is the glossy green handset. Adaptive icon layers are 108 dp with the middle 72 dp visible, so the 1024-unit
tile sits at 256..1280 of a 1536-unit layer. Vector drawables can't draw the glass shading, so the
layers are PNGs, rendered with headless Chrome/Edge. Run from the repo root after changing the design:

    python tool/icons/render_icons.py
"""
import os
import pathlib
import subprocess
import tempfile

RES = pathlib.Path("android/app/src/main/res/drawable-nodpi")
PREVIEW = pathlib.Path("assets/app_icons")
PLAY = pathlib.Path("docs/play-icon.png")
L, T, O = 1536, 1024, 256  # layer, tile, tile offset in the layer
PX = 648  # 108 dp at 6x, headroom over xxxhdpi for launchers that enlarge icons

HANDSET = "M19.23 15.26l-2.54-.29c-.61-.07-1.21.14-1.64.57l-1.84 1.84c-2.83-1.44-5.15-3.75-6.59-6.59l1.85-1.85c.43-.43.64-1.03.57-1.64l-.29-2.52c-.12-1.01-.97-1.77-1.99-1.77H5.03c-1.13 0-2.07.94-2 2.07.53 8.54 7.36 15.36 15.89 15.89 1.13.07 2.07-.87 2.07-2v-1.73c.01-1.01-.75-1.86-1.76-1.98z"
BODY = "M40 486c0-118 104-178 240-178s240 60 240 178c0 22-18 38-40 38H80c-22 0-40-16-40-38z"


def handset(cx, cy, size, fill, w, rotate=0, extra=""):
    """The rounded handset centred on (cx, cy), [size] across including its [w]-wide rounding."""
    f = (size - 2 * w) * 24 / 18
    k = f / 24
    return (f'<path transform="rotate({rotate} {cx} {cy}) translate({cx - f / 2:.2f} {cy - f / 2:.2f}) scale({k:.4f})" d="{HANDSET}" '
            f'fill="{fill}" stroke="{fill}" stroke-width="{2 * w / k:.3f}" stroke-linejoin="round" {extra}/>')


def thin_handset(cx, cy, size, fill, w, rotate=0, extra=""):
    """The launcher's slim handset as plain geometry: the glyph with 15/28 of [w]'s rounding."""
    t = w * 15 / 28
    return handset(cx, cy, size - 2 * (w - t), fill, t, rotate, extra)


# A round-joined stroke rounds the handset's pads (28 units out at full rounding).
W = 28

# vivo Origin Island images (CallNotifications.kt): 72 dp at 3x. The balls are the call screen's
# solidBody + solidGlow (call_controls.dart); the glyphs are the Glossy launcher's slim handset, flat.
ISL = 216
GS = ISL * .46 / (0.59 * T)  # island glyph : launcher glyph
ANSWER, END = "#2FAE52", "#D2463A"
VOLUME = "M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"


def mix(a, b, t):
    ca, cb = (int(a[i:i + 2], 16) for i in (1, 3, 5)), (int(b[i:i + 2], 16) for i in (1, 3, 5))
    return "#" + "".join(f"{round(x + (y - x) * t):02X}" for x, y in zip(ca, cb))


def ball(color, rotate):
    """IncomingControls' ball (solidBody + solidGlow, no drop glow) with a flat white handset."""
    r = ISL / 2
    return (f'<defs><linearGradient id="body" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{mix(color, "#000000", .1)}"/>'
            f'<stop offset=".55" stop-color="{color}"/><stop offset="1" stop-color="{mix(color, "#FFFFFF", .14)}"/></linearGradient>'
            '<linearGradient id="lit" x1="0" y1="0" x2="0" y2="1"><stop offset=".5" stop-color="#FFFFFF" stop-opacity="0"/>'
            '<stop offset="1" stop-color="#FFFFFF" stop-opacity=".24"/></linearGradient></defs>'
            f'<circle cx="{r}" cy="{r}" r="{r}" fill="url(#body)"/><circle cx="{r}" cy="{r}" r="{r}" fill="url(#lit)"/>'
            f'<circle cx="{r}" cy="{r}" r="{r - 1.2}" fill="none" stroke="#FFFFFF" stroke-opacity=".18" stroke-width="2.4"/>'
            + thin_handset(r, r, ISL * .46, "#FFFFFF", W * GS, rotate))


def speaker(fill, glyph):
    """CallControlButton's Speaker: a flat disc and the volume glyph, rounded like the handset."""
    return (f'<circle cx="{ISL / 2}" cy="{ISL / 2}" r="{ISL / 2}" fill="{fill}"/>'
            f'<path transform="translate({ISL * .27} {ISL * .27}) scale({ISL * .46 / 18:.4f}) translate(-3 -3)" '
            f'd="{VOLUME}" fill="{glyph}" stroke="{glyph}" stroke-width=".5" stroke-linejoin="round"/>')


cpk = ISL * .4 / 484  # LetterAvatar's person is about 40% of the disc
ISLAND = {
    "island_answer": ball(ANSWER, 0),
    "island_decline": ball(END, 135),  # the handset hung up
    # the collapsed island's glyph (also the ongoing call's small icon)
    "island_phone": thin_handset(ISL / 2, ISL / 2, ISL * .75, ANSWER, W * ISL / (0.59 * T)),  # the old Icon's 18 of 24
    # LetterAvatar's no-photo person
    "island_caller": (f'<circle cx="{ISL / 2}" cy="{ISL / 2}" r="{ISL / 2}" fill="#2C2C2E"/>'
                      f'<g fill="#9E9EA4" transform="translate({ISL / 2 - 280 * cpk:.2f} {ISL / 2 - 282 * cpk:.2f}) scale({cpk:.4f})">'
                      f'<circle cx="280" cy="168" r="128"/><path d="{BODY}"/></g>'),
    # frosted with a white glyph, or white with a dark glyph when on
    "island_speaker": speaker("#FFFFFF2E", "#FFFFFF"),
    "island_speaker_on": speaker("#FFFFFFEB", "#111418"),
}


def svg(body, view=f"0 0 {L} {L}", size=PX):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" viewBox="{view}">{body}</svg>'


def browser():
    for p in (r"C:\Program Files\Google\Chrome\Application\chrome.exe",
              r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"):
        if os.path.exists(p):
            return p
    raise SystemExit("needs Chrome or Edge")


def render(markup, out, size):
    with tempfile.TemporaryDirectory() as tmp:
        page = pathlib.Path(tmp, "icon.html")
        page.write_text(f'<html><body style="margin:0;background:transparent">{markup}</body></html>', encoding="utf-8")
        subprocess.run([browser(), "--headless", "--disable-gpu", "--hide-scrollbars", "--force-device-scale-factor=1",
                        "--default-background-color=00000000", f"--window-size={size},{size}",
                        f"--screenshot={out.resolve()}", page.as_uri()], check=True, capture_output=True)
    assert out.exists(), out


# Glossy, the default launcher pair since beta 7: the same glyphs, glossy white-to-mint with a soft
# shadow on a brighter green.
def tile_grad(top, bottom):
    return (f'<defs><linearGradient id="bg" x1="0" y1="{O}" x2="0" y2="{O + T}" gradientUnits="userSpaceOnUse">'
            f'<stop stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>'
            f'<rect width="{L}" height="{L}" fill="url(#bg)"/>')


GLOSSY_PHONE_BG = tile_grad("#14DD5E", "#00C23A")
# Drawn like One Recorder's wave (plain geometry, a top-to-bottom gloss and a drop shadow, no
# filter thinning): vivo's Dark icon style then tints it green, as it does the Recorder's.
hs_ = 0.62 * T
GLOSSY_PHONE_FG = (f'<defs><linearGradient id="hgloss" x1="0" y1="{O + (T - hs_) / 2:.0f}" x2="0" y2="{O + (T + hs_) / 2:.0f}" '
                   'gradientUnits="userSpaceOnUse"><stop stop-color="#FFFFFF"/><stop offset=".55" stop-color="#EEFCF4"/>'
                   '<stop offset="1" stop-color="#BDF0D8"/></linearGradient>'
                   '<filter id="hdrop" x="-20%" y="-20%" width="140%" height="150%">'
                   '<feDropShadow dx="0" dy="11" stdDeviation="13" flood-color="#006E2A" flood-opacity=".35"/></filter></defs>'
                   f'<g filter="url(#hdrop)">' + thin_handset(O + T / 2, O + T / 2, hs_, "url(#hgloss)", W) + '</g>')

RES.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)
for name, body in {"ic_launcher_background": GLOSSY_PHONE_BG, "ic_launcher_foreground": GLOSSY_PHONE_FG}.items():
    render(svg(body), RES / f"{name}.png", PX)
# Themed icon (<monochrome>): the launcher's slim handset as one white path in a 108-unit canvas; a
# round-joined stroke gives it the foreground's rounding (without it, it's the stock Material glyph).
def flat_path(d, k, tx, ty):
    """[d] scaled by [k] and moved by (tx, ty), baked into the path data (absolute M/L/C/H/V, relative rest)."""
    import re
    out, cmd, i = [], "", 0
    for tok in re.findall(r"[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)", d):
        if tok.isalpha():
            cmd, i = tok, 0
            out.append(tok)
            continue
        v = float(tok)
        if cmd.islower():
            v *= k
        elif cmd == "H" or (cmd in "MLC" and i % 2 == 0):
            v = v * k + tx
        else:
            v = v * k + ty
        i += 1
        out.append(f"{v:.2f}")
    return re.sub(r" ?([A-Za-z]) ?", lambda m: m.group(1), " ".join(out))


def v_handset(size, w):
    """handset() as a vector path: [size] across including the [w]-wide rounding."""
    f = (size - 2 * w) * 24 / 18
    k = f / 24 * 108 / L
    off = (O + T / 2 - f / 2) * 108 / L
    return (f'<path android:fillColor="#FFFFFFFF" android:strokeColor="#FFFFFFFF" android:strokeWidth="{2 * w * 108 / L:.3f}" '
            f'android:strokeLineJoin="round" android:pathData="{flat_path(HANDSET, k, off, off)}"/>')


for name, body in {"ic_launcher_monochrome": v_handset(0.62 * T - 2 * (W - W * 15 / 28), W * 15 / 28)}.items():  # thin_handset
    pathlib.Path("android/app/src/main/res/drawable", f"{name}.xml").write_text(
        "<!-- Rendered by tool/icons/render_icons.py: the launcher glyph, flat, for themed icons. -->\n"
        '<vector xmlns:android="http://schemas.android.com/apk/res/android" android:width="108dp" android:height="108dp" '
        f'android:viewportWidth="108" android:viewportHeight="108">{body}</vector>\n', encoding="utf-8")
# The visible tile, which the website uses as its icon (site/scripts/sync-one-dialer.mjs).
render(svg(GLOSSY_PHONE_BG + GLOSSY_PHONE_FG, f"{O} {O} {T} {T}", 192), PREVIEW / "default_phone.png", 192)
# Play wants the full square (it rounds the corners itself): the visible tile of both layers.
render(svg(GLOSSY_PHONE_BG + GLOSSY_PHONE_FG, f"{O} {O} {T} {T}", 512), PLAY, 512)
for name, body in ISLAND.items():
    render(svg(body, f"0 0 {ISL} {ISL}", ISL), RES / f"{name}.png", ISL)
# The keypad Call button's glyph: Glossy's slimmed handset, plain white (tinted in Flutter), no shadow.
HS, hs = 144, 0.62 * T
THIN = ('<filter id="thinw" x="-20%" y="-20%" width="140%" height="140%">'
        '<feMorphology in="SourceAlpha" operator="erode" radius="13" result="e"/>'
        '<feGaussianBlur in="e" stdDeviation="10" result="b"/>'
        '<feComponentTransfer in="b" result="m"><feFuncA type="linear" slope="12" intercept="-5.5"/></feComponentTransfer>'
        '<feComposite in="SourceGraphic" in2="m" operator="in"/></filter>')
pathlib.Path("assets/icons").mkdir(parents=True, exist_ok=True)
render(svg(f'<defs>{THIN}</defs><g filter="url(#thinw)">' + handset(O + T / 2, O + T / 2, hs, "#FFFFFF", W) + '</g>',
           f"{O + (T - hs) / 2:.1f} {O + (T - hs) / 2:.1f} {hs:.1f} {hs:.1f}", HS), pathlib.Path("assets/icons/handset.png"), HS)
print("rendered to", RES, "and", PLAY)


# The return-to-call button's glyph: the same handset, smaller at the bottom left, with sound waves.
def waves(x0, s, fill):
    cx, cy, sw = x0 + .46 * s, x0 + .54 * s, .085 * s
    return "".join(f'<path d="M{cx:.1f} {cy - r:.1f}A{r:.1f} {r:.1f} 0 0 1 {cx + r:.1f} {cy:.1f}" fill="none" stroke="{fill}" '
                   f'stroke-width="{sw:.1f}" stroke-linecap="round"/>' for r in (.22 * s, .4 * s))


x0 = O + (T - hs) / 2
render(svg(f'<defs>{THIN}</defs><g filter="url(#thinw)">' + handset(x0 + .42 * hs, x0 + .58 * hs, .84 * hs, "#FFFFFF", W * .84) + '</g>'
           + waves(x0, hs, "#FFFFFF"), f"{x0:.1f} {x0:.1f} {hs:.1f} {hs:.1f}", HS), pathlib.Path("assets/icons/handset_talk.png"), HS)


# The contact page's Message and Video tiles: solid, softly rounded glyphs that sit with the handset
# (ColorOS's filled set). Drawn on a 24-unit grid, white (tinted in Flutter), filling their image.
def glyph(body, name):
    render(svg(body, "0 0 24 24", HS), pathlib.Path(f"assets/icons/{name}.png"), HS)


glyph('<mask id="m"><rect width="24" height="24" fill="#fff"/>'
      '<path d="M7 8.2h10M7 12.8h6" stroke="#000" stroke-width="2.3" stroke-linecap="round"/></mask>'
      '<g mask="url(#m)" fill="#FFFFFF" stroke="#FFFFFF" stroke-width="1.2" stroke-linejoin="round">'
      '<rect x="2.1" y="2.6" width="19.8" height="15.6" rx="5"/>'
      '<path d="M6.4 16.5L5.4 21.5L12 17.6Z"/></g>', "message")
glyph('<g fill="#FFFFFF" stroke="#FFFFFF" stroke-width="1.2" stroke-linejoin="round">'
      '<rect x="1.6" y="5.4" width="14.4" height="13.2" rx="4"/>'
      '<path d="M18 10.3L21.3 8.1Q22.4 7.4 22.4 8.7V15.3Q22.4 16.6 21.3 15.9L18 13.7Z"/></g>', "video")


# Call-type marks for call rows and history: a plain arrow (in or out) or a barred circle.
def arrow(mark, name):
    glyph(f'<g fill="none" stroke="#FFFFFF" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round">{mark}</g>',
          name)


arrow('<path d="M6 6L17.5 17.5M8.5 17.5H17.5V8.5"/>', "arrow_in")
arrow('<path d="M6 18L17.5 6.5M8.5 6.5H17.5V15.5"/>', "arrow_out")
arrow('<circle cx="12" cy="12" r="7.5"/><path d="M6.7 17.3L17.3 6.7"/>', "arrow_blocked")


# The details page's Add tile: a solid person with a plus, beside the Call and Message glyphs.
glyph('<g fill="#FFFFFF" stroke="#FFFFFF" stroke-width="1.2" stroke-linejoin="round">'
      '<circle cx="9" cy="7.6" r="4.1"/>'
      '<path d="M1.8 20.2C1.8 16.3 5 13.8 9 13.8S16.2 16.3 16.2 20.2V21H1.8Z"/></g>'
      '<path d="M19.6 6V13M16.1 9.5H23.1" stroke="#FFFFFF" stroke-width="2.3" stroke-linecap="round"/>', "add_contact")


# One Recorder (companion/): Phone's Glossy tile with a glossy sound wave (rounded bars) in
# place of the handset, so it reads as One Dialer's sibling.
REC = pathlib.Path("companion/app/src/main/res/drawable-nodpi")
WAVE = (.26, .5, .78, 1, .66, .9, .44, .22)  # bar heights, as a share of the tallest
bw, gap, tall = .064 * T, .046 * T, .58 * T
x = O + (T - len(WAVE) * bw - (len(WAVE) - 1) * gap) / 2
BARS = "".join(f'<rect x="{x + i * (bw + gap):.1f}" y="{O + T / 2 - h * tall / 2:.1f}" width="{bw:.1f}" height="{h * tall:.1f}" rx="{bw / 2:.1f}"/>'
               for i, h in enumerate(WAVE))
RECORDER_FG = (f'<defs><linearGradient id="wgloss" x1="0" y1="{O + (T - tall) / 2:.0f}" x2="0" y2="{O + (T + tall) / 2:.0f}" '
               'gradientUnits="userSpaceOnUse"><stop stop-color="#FFFFFF"/><stop offset=".55" stop-color="#EEFCF4"/>'
               '<stop offset="1" stop-color="#BDF0D8"/></linearGradient>'
               '<filter id="wdrop" x="-20%" y="-20%" width="140%" height="150%">'
               '<feDropShadow dx="0" dy="11" stdDeviation="13" flood-color="#006E2A" flood-opacity=".35"/></filter></defs>'
               f'<g filter="url(#wdrop)" fill="url(#wgloss)">{BARS}</g>')
REC.mkdir(parents=True, exist_ok=True)
render(svg(GLOSSY_PHONE_BG), REC / "ic_launcher_background.png", PX)
render(svg(RECORDER_FG), REC / "ic_launcher_foreground.png", PX)


# The nav bar's tabs: the handset outlined (Calls, unselected) and ColorOS's two people, the front one
# solid when selected and outlined when not; the one behind is an outline cut short where they overlap.
NAV = 'stroke="#FFFFFF" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round"'
glyph(f'<path d="{HANDSET}" fill="none" {NAV}/>', "handset_outline")
FRONT = ('<circle cx="9.5" cy="8.2" r="4"/>'
         '<path d="M2.6 20.4C2.6 16.4 5.6 14.2 9.5 14.2S16.4 16.4 16.4 20.4Z"/>')
BEHIND = ('<mask id="b"><rect width="24" height="24" fill="#fff"/>'
          f'<g fill="#000" stroke="#000" stroke-width="5" stroke-linejoin="round">{FRONT}</g></mask>'
          f'<g mask="url(#b)" fill="none" {NAV}><circle cx="15.8" cy="6.2" r="3.6"/>'
          '<path d="M17.4 12.6C20.1 13 21.6 15.1 21.6 17.8"/></g>')
glyph(BEHIND + f'<g fill="#FFFFFF" {NAV}>{FRONT}</g>', "contacts")
glyph(BEHIND + f'<g fill="none" {NAV}>{FRONT}</g>', "contacts_outline")
