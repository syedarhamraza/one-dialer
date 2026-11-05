"""Renders the launcher icons (Phone, Contacts) in Glossy (the default) and Classic, their Settings
previews, the Play Store icon and the vivo island images from SVG.

The design is the flat green pair from Figma ("One Dialer — App Icons"), with a light glass rim
on the glyphs. Adaptive icon layers are 108 dp with the middle 72 dp visible, so the 1024-unit
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


def rgba(h, a):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return f"0 0 0 0 {r:.3f} 0 0 0 0 {g:.3f} 0 0 0 0 {b:.3f} 0 0 0 {a} 0"


def glass_filter(fid):
    """The glyphs' light glass: a faint shadow, a thin white rim on top and a softer green one underneath."""
    alpha = '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>'
    inner = lambda dx, dy, blur, c, a, prev, out: (
        alpha + f'<feOffset dx="{dx}" dy="{dy}"/><feGaussianBlur stdDeviation="{blur / 2}"/>'
        '<feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>'
        f'<feColorMatrix type="matrix" values="{rgba(c, a)}"/><feBlend in2="{prev}" result="{out}"/>')
    return (
        f'<filter id="{fid}" x="0" y="0" width="{L}" height="{L}" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
        + alpha + '<feOffset dy="6"/><feGaussianBlur stdDeviation="10"/>'
        f'<feColorMatrix type="matrix" values="{rgba("#00451F", .12)}" result="drop"/>'
        '<feBlend in="SourceGraphic" in2="drop" result="shape"/>'
        + inner(0, 4, 3, "#FFFFFF", .9, "shape", "rim")
        + inner(0, -4, 6, "#1FA85C", .25, "rim", "out")
        + "</filter>")


def handset(cx, cy, size, fill, w, rotate=0, extra=""):
    """The rounded handset centred on (cx, cy), [size] across including its [w]-wide rounding."""
    f = (size - 2 * w) * 24 / 18
    k = f / 24
    return (f'<path transform="rotate({rotate} {cx} {cy}) translate({cx - f / 2:.2f} {cy - f / 2:.2f}) scale({k:.4f})" d="{HANDSET}" '
            f'fill="{fill}" stroke="{fill}" stroke-width="{2 * w / k:.3f}" stroke-linejoin="round" {extra}/>')


def thin_handset(cx, cy, size, fill, w, rotate=0, extra=""):
    """Glossy's slimmer handset as plain geometry: the same glyph with 15/28 of [w]'s rounding
    (Glossy erodes Classic's 28-unit rounding by 13), so it also works in vector XML."""
    t = w * 15 / 28
    return handset(cx, cy, size - 2 * (w - t), fill, t, rotate, extra)


FROST = ('<linearGradient id="frost" x1="0" y1="0" x2="0" y2="1">'
         '<stop stop-color="#FFFFFF"/><stop offset="1" stop-color="#E6FAEE"/></linearGradient>')


def tile_bg(top, bottom, extra=""):
    return (f'<defs><linearGradient id="bg" x1="0" y1="{O}" x2="0" y2="{O + T}" gradientUnits="userSpaceOnUse">'
            f'<stop stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>'
            f'<radialGradient id="glow" cx="{O + 250}" cy="{O - 10}" r="550" gradientUnits="userSpaceOnUse">'
            '<stop stop-color="#FFFFFF" stop-opacity=".12"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient></defs>'
            f'<rect width="{L}" height="{L}" fill="url(#bg)"/><rect width="{L}" height="{L}" fill="url(#glow)"/>{extra}')


SPINE = (f'<defs><linearGradient id="spine" x1="0" y1="{O}" x2="0" y2="{O + T}" gradientUnits="userSpaceOnUse">'
         '<stop stop-color="#04A856"/><stop offset="1" stop-color="#007A36"/></linearGradient></defs>'
         f'<rect x="{O + T - 150}" width="{L}" height="{L}" fill="url(#spine)" opacity=".9"/>'
         + "".join(f'<rect x="{O + T - 140}" y="{O + y}" width="14" height="110" rx="7" fill="#FFFFFF" fill-opacity=".28"/>' for y in (300, 470, 640)))

# The handset fills 59% of the tile like vivo's; a round-joined stroke rounds its pads (28 units out).
W = 28
HANDSET_FG = (f'<defs>{FROST}{glass_filter("glass")}</defs><g filter="url(#glass)"><g opacity=".95">'
              + handset(O + T / 2, O + T / 2, 0.59 * T, "url(#frost)", W) + '</g></g>')

# The person is 54% of the tile tall, a little left of centre to clear the spine.
pk = 0.54 * T / 484
px, py = O + 0.47 * T - 280 * pk, O + T / 2 - 282 * pk
PERSON_FG = (f'<defs>{FROST}{glass_filter("glass")}</defs><g filter="url(#glass)"><g opacity=".95" fill="url(#frost)" '
             f'transform="translate({px:.2f} {py:.2f}) scale({pk:.4f})"><circle cx="280" cy="168" r="128"/><path d="{BODY}"/></g></g>')

PHONE_BG = tile_bg("#1ED760", "#009A3E")
CONTACTS_BG = tile_bg("#14D16E", "#00964A", SPINE)

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
# shadow on a brighter green; the Contacts tile has three address-book tabs down its right edge.
# The original frosted pair stays as Classic (Settings › More settings › App icon, AppIcons.kt).
def tile_grad(top, bottom):
    return (f'<defs><linearGradient id="bg" x1="0" y1="{O}" x2="0" y2="{O + T}" gradientUnits="userSpaceOnUse">'
            f'<stop stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient></defs>'
            f'<rect width="{L}" height="{L}" fill="url(#bg)"/>')


def tabs():
    x, cuts = O + .86 * T, (O + .38 * T, O + .69 * T)
    return ('<defs><linearGradient id="shade" x1="0" y1="0" x2="1" y2="0"><stop stop-color="#005A1E" stop-opacity=".28"/>'
            '<stop offset="1" stop-color="#005A1E" stop-opacity="0"/></linearGradient></defs>'
            f'<rect x="{x:.0f}" width="{L}" height="{cuts[0]:.0f}" fill="#00C640"/>'
            f'<rect x="{x:.0f}" y="{cuts[0]:.0f}" width="{L}" height="{cuts[1] - cuts[0]:.0f}" fill="#00B532"/>'
            f'<rect x="{x:.0f}" y="{cuts[1]:.0f}" width="{L}" height="{L}" fill="#00A529"/>'
            f'<rect x="{x:.0f}" width="{.036 * T:.0f}" height="{L}" fill="url(#shade)"/>')


GLOSS = ('<linearGradient id="gloss" x1="0" y1="0" x2=".4" y2="1"><stop stop-color="#FFFFFF"/>'
         '<stop offset=".55" stop-color="#EEFCF4"/><stop offset="1" stop-color="#BDF0D8"/></linearGradient>'
         '<linearGradient id="head" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#F2FFF8"/><stop offset="1" stop-color="#B5F2D0"/></linearGradient>'
         '<linearGradient id="body" x1="0" y1="0" x2="1" y2=".6"><stop stop-color="#F2FCF6"/>'
         '<stop offset=".6" stop-color="#CBF4DD"/><stop offset="1" stop-color="#95E6B8"/></linearGradient>'
         '<filter id="drop" x="-20%" y="-20%" width="140%" height="150%">'
         '<feDropShadow dx="0" dy="11" stdDeviation="13" flood-color="#006E2A" flood-opacity=".35"/></filter>'
         # Thins the handset evenly; the blur and threshold round the corners the erosion squares off.
         '<filter id="thin" x="-20%" y="-20%" width="140%" height="150%">'
         '<feMorphology in="SourceAlpha" operator="erode" radius="13" result="e"/>'
         '<feGaussianBlur in="e" stdDeviation="10" result="b"/>'
         '<feComponentTransfer in="b" result="m"><feFuncA type="linear" slope="12" intercept="-5.5"/></feComponentTransfer>'
         '<feComposite in="SourceGraphic" in2="m" operator="in" result="t"/>'
         '<feDropShadow in="t" dx="0" dy="11" stdDeviation="13" flood-color="#006E2A" flood-opacity=".35"/></filter>')

GLOSSY_PHONE_BG = tile_grad("#14DD5E", "#00C23A")
GLOSSY_CONTACTS_BG = tile_grad("#10DE68", "#00C43F") + tabs()
# Slimmer than Classic: less rounding on the handset, a smaller head and a narrower body.
GLOSSY_PHONE_FG = (f'<defs>{GLOSS}</defs><g filter="url(#thin)">'
                   + handset(O + T / 2, O + T / 2, 0.62 * T, "url(#gloss)", W) + '</g>')
GLOSSY_PERSON_FG = (f'<defs>{GLOSS}</defs><g filter="url(#drop)" transform="translate({px:.2f} {py:.2f}) scale({pk:.4f})">'
                    f'<circle cx="280" cy="178" r="112" fill="url(#head)"/>'
                    f'<path d="{BODY}" fill="url(#body)" transform="translate(280 0) scale(.86 .92) translate(-280 42)"/></g>')

RES.mkdir(parents=True, exist_ok=True)
PREVIEW.mkdir(parents=True, exist_ok=True)
for name, body in {"ic_launcher_background": GLOSSY_PHONE_BG, "ic_launcher_foreground": GLOSSY_PHONE_FG,
                   "ic_contacts_background": GLOSSY_CONTACTS_BG, "ic_contacts_foreground": GLOSSY_PERSON_FG,
                   "ic_classic_phone_background": PHONE_BG, "ic_classic_phone_foreground": HANDSET_FG,
                   "ic_classic_contacts_background": CONTACTS_BG, "ic_classic_contacts_foreground": PERSON_FG}.items():
    render(svg(body), RES / f"{name}.png", PX)
# Settings previews: the visible tile, which the app rounds itself.
for name, body in {"default_phone": GLOSSY_PHONE_BG + GLOSSY_PHONE_FG, "default_contacts": GLOSSY_CONTACTS_BG + GLOSSY_PERSON_FG,
                   "classic_phone": PHONE_BG + HANDSET_FG, "classic_contacts": CONTACTS_BG + PERSON_FG}.items():
    render(svg(body, f"{O} {O} {T} {T}", 192), PREVIEW / f"{name}.png", 192)
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
