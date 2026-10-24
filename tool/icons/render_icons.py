"""Renders the launcher icons (Phone, Contacts), the Play Store icon and the vivo island images from SVG.

The design is the green frosted-glass pair from Figma ("One Dialer — App Icons"). Adaptive icon
layers are 108 dp with the middle 72 dp visible, so the 1024-unit tile sits at 256..1280 of a
1536-unit layer. Vector drawables can't draw the glass shading, so the layers are PNGs, rendered
with headless Chrome/Edge. Run from the repo root after changing the design:

    python tool/icons/render_icons.py
"""
import os
import pathlib
import subprocess
import tempfile

RES = pathlib.Path("android/app/src/main/res/drawable-nodpi")
PLAY = pathlib.Path("docs/play-icon.png")
L, T, O = 1536, 1024, 256  # layer, tile, tile offset in the layer
PX = 648  # 108 dp at 6x, headroom over xxxhdpi for launchers that enlarge icons

HANDSET = "M19.23 15.26l-2.54-.29c-.61-.07-1.21.14-1.64.57l-1.84 1.84c-2.83-1.44-5.15-3.75-6.59-6.59l1.85-1.85c.43-.43.64-1.03.57-1.64l-.29-2.52c-.12-1.01-.97-1.77-1.99-1.77H5.03c-1.13 0-2.07.94-2 2.07.53 8.54 7.36 15.36 15.89 15.89 1.13.07 2.07-.87 2.07-2v-1.73c.01-1.01-.75-1.86-1.76-1.98z"
BODY = "M40 486c0-118 104-178 240-178s240 60 240 178c0 22-18 38-40 38H80c-22 0-40-16-40-38z"


def rgba(h, a):
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (1, 3, 5))
    return f"0 0 0 0 {r:.3f} 0 0 0 0 {g:.3f} 0 0 0 0 {b:.3f} 0 0 0 {a} 0"


def glass_filter(fid, s=1, drop="#00451F", drop_a=.38, tint="#1FA85C"):
    """Figma's effects on the glyphs: a deep drop shadow, a white bevel top-left, a tinted one bottom-right.
    [s] scales the offsets and blurs (1 = the 1024-unit launcher tile)."""
    alpha = '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>'
    inner = lambda dx, dy, blur, c, a, prev, out: (
        alpha + f'<feOffset dx="{dx * s}" dy="{dy * s}"/><feGaussianBlur stdDeviation="{blur * s / 2}"/>'
        '<feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>'
        f'<feColorMatrix type="matrix" values="{rgba(c, a)}"/><feBlend in2="{prev}" result="{out}"/>')
    return (
        f'<filter id="{fid}" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB">'
        + alpha + f'<feOffset dy="{22 * s}"/><feGaussianBlur stdDeviation="{22 * s}"/>'
        f'<feColorMatrix type="matrix" values="{rgba(drop, drop_a)}" result="drop"/>'
        '<feBlend in="SourceGraphic" in2="drop" result="shape"/>'
        + inner(-4, 8, 10, "#FFFFFF", 1, "shape", "bevel")
        + inner(6, -14, 22, tint, .6, "bevel", "out")
        + "</filter>")


def handset(cx, cy, size, fill, w, rotate=0, extra=""):
    """The rounded handset centred on (cx, cy), [size] across including its [w]-wide rounding."""
    f = (size - 2 * w) * 24 / 18
    k = f / 24
    return (f'<path transform="rotate({rotate} {cx} {cy}) translate({cx - f / 2:.2f} {cy - f / 2:.2f}) scale({k:.4f})" d="{HANDSET}" '
            f'fill="{fill}" stroke="{fill}" stroke-width="{2 * w / k:.3f}" stroke-linejoin="round" {extra}/>')


FROST = ('<linearGradient id="frost" x1="0" y1="0" x2="0" y2="1">'
         '<stop stop-color="#FFFFFF"/><stop offset=".55" stop-color="#F0FFF5"/><stop offset="1" stop-color="#C2F5D6"/></linearGradient>')


def tile_bg(top, bottom, extra=""):
    return (f'<defs><linearGradient id="bg" x1="0" y1="{O}" x2="0" y2="{O + T}" gradientUnits="userSpaceOnUse">'
            f'<stop stop-color="{top}"/><stop offset="1" stop-color="{bottom}"/></linearGradient>'
            f'<radialGradient id="glow" cx="{O + 250}" cy="{O - 10}" r="550" gradientUnits="userSpaceOnUse">'
            '<stop stop-color="#FFFFFF" stop-opacity=".32"/><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"/></radialGradient></defs>'
            f'<rect width="{L}" height="{L}" fill="url(#bg)"/><rect width="{L}" height="{L}" fill="url(#glow)"/>{extra}')


SPINE = (f'<defs><linearGradient id="spine" x1="0" y1="{O}" x2="0" y2="{O + T}" gradientUnits="userSpaceOnUse">'
         '<stop stop-color="#18B873"/><stop offset="1" stop-color="#007A4C"/></linearGradient></defs>'
         f'<rect x="{O + T - 150}" width="{L}" height="{L}" fill="url(#spine)" opacity=".9"/>'
         + "".join(f'<rect x="{O + T - 140}" y="{O + y}" width="14" height="110" rx="7" fill="#FFFFFF" fill-opacity=".28"/>' for y in (300, 470, 640)))

# The handset fills 59% of the tile like vivo's; a round-joined stroke rounds its pads (28 units out).
W = 28
HANDSET_FG = (f'<defs>{FROST}{glass_filter("glass")}</defs><g filter="url(#glass)"><g opacity=".88">'
              + handset(O + T / 2, O + T / 2, 0.59 * T, "url(#frost)", W) + '</g></g>')

# The person is 54% of the tile tall, a little left of centre to clear the spine.
pk = 0.54 * T / 484
px, py = O + 0.47 * T - 280 * pk, O + T / 2 - 282 * pk
PERSON_FG = (f'<defs>{FROST}{glass_filter("glass")}</defs><g filter="url(#glass)"><g opacity=".88" fill="url(#frost)" '
             f'transform="translate({px:.2f} {py:.2f}) scale({pk:.4f})"><circle cx="280" cy="168" r="128"/><path d="{BODY}"/></g></g>')

PHONE_BG = tile_bg("#4DEA8E", "#04B457")
CONTACTS_BG = tile_bg("#3FE3A0", "#00A86B", SPINE)

# vivo Origin Island images (CallNotifications.kt): 72 dp at 3x. The balls are the call screen's
# solidBody + solidGlow (call_controls.dart) with a glass rim; the glyphs are the launcher's frosted handset.
ISL = 216
GS = ISL * .46 / (0.59 * T)  # island glyph : launcher glyph
ANSWER, END = "#2FAE52", "#D2463A"
VOLUME = "M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"


def mix(a, b, t):
    ca, cb = (int(a[i:i + 2], 16) for i in (1, 3, 5)), (int(b[i:i + 2], 16) for i in (1, 3, 5))
    return "#" + "".join(f"{round(x + (y - x) * t):02X}" for x, y in zip(ca, cb))


def frost(bottom):
    """The launcher's frost, tinted toward [bottom] to suit the button under it."""
    return FROST.replace("#F0FFF5", mix("#FFFFFF", bottom, .4)).replace("#C2F5D6", bottom)


def disc(fill_defs, fill, rim=.18):
    """A round button: its fill, a light rim, a soft light along the top inside edge."""
    r = ISL / 2
    return (f'<defs>{fill_defs}<filter id="lift" x="-10%" y="-10%" width="120%" height="120%">'
            '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="a"/>'
            f'<feOffset dy="4"/><feGaussianBlur stdDeviation="3"/><feComposite in2="a" operator="arithmetic" k2="-1" k3="1"/>'
            f'<feColorMatrix type="matrix" values="{rgba("#FFFFFF", .35)}"/><feBlend in2="SourceGraphic"/></filter></defs>'
            f'<circle cx="{r}" cy="{r}" r="{r}" fill="{fill}" filter="url(#lift)"/>'
            f'<circle cx="{r}" cy="{r}" r="{r - 1.2}" fill="none" stroke="#FFFFFF" stroke-opacity="{rim}" stroke-width="2.4"/>')


def ball(color, rotate):
    body = (f'<linearGradient id="body" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{mix(color, "#000000", .1)}"/>'
            f'<stop offset=".55" stop-color="{color}"/><stop offset="1" stop-color="{mix(color, "#FFFFFF", .14)}"/></linearGradient>'
            '<linearGradient id="lit" x1="0" y1="0" x2="0" y2="1"><stop offset=".5" stop-color="#FFFFFF" stop-opacity="0"/>'
            '<stop offset="1" stop-color="#FFFFFF" stop-opacity=".24"/></linearGradient>')
    return (disc(body + frost(mix(color, "#FFFFFF", .75)) + glass_filter("glass", GS * 1.6, mix(color, "#000000", .6), .35, mix(color, "#000000", .15)), "url(#body)")
            + f'<circle cx="{ISL / 2}" cy="{ISL / 2}" r="{ISL / 2}" fill="url(#lit)"/>'
            + f'<g filter="url(#glass)">{handset(ISL / 2, ISL / 2, ISL * .46, "url(#frost)", W * GS, rotate)}</g>')


def speaker(fill, fill_a, glyph, glyph_fx):
    return (disc(frost("#DADAE0") + glass_filter("glass", GS * 1.6, "#000000", .3, "#7A7A84"), fill, .22).replace(
                f'fill="{fill}"', f'fill="{fill}" fill-opacity="{fill_a}"', 1)
            + f'<g filter="{glyph_fx}"><path transform="translate({ISL * .27} {ISL * .27}) scale({ISL * .46 / 18:.4f}) translate(-3 -3)" '
              f'd="{VOLUME}" fill="{glyph}" stroke="{glyph}" stroke-width=".5" stroke-linejoin="round"/></g>')


# The collapsed island's glyph (also the ongoing call's small icon): the handset lit in Answer green.
ANSWER_LIT = (f'<linearGradient id="ans" x1="0" y1="0" x2="0" y2="1"><stop stop-color="{mix(ANSWER, "#000000", .1)}"/>'
              f'<stop offset=".55" stop-color="{ANSWER}"/><stop offset="1" stop-color="#5CCB7B"/></linearGradient>')
cpk = ISL * .54 / 484
ISLAND = {
    "island_answer": ball(ANSWER, 0),
    "island_decline": ball(END, 135),  # the handset hung up
    "island_phone": f'<defs>{ANSWER_LIT}{glass_filter("glass", ISL / (0.59 * T) * .9, "#0B4A22", .0, "#1E8A40")}</defs>'
                    f'<g filter="url(#glass)">{handset(ISL / 2, ISL / 2, ISL * .92, "url(#ans)", W * ISL / (0.59 * T))}</g>',
    # LetterAvatar's no-photo person, in frosted glass on its dark disc
    "island_caller": (disc('<linearGradient id="av" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#3A3A3F"/><stop offset="1" stop-color="#26262A"/></linearGradient>'
                           '<linearGradient id="pf" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#C9C9D1"/><stop offset="1" stop-color="#8E8E98"/></linearGradient>'
                           + glass_filter("glass", GS * 1.6, "#000000", .35, "#55555E"), "url(#av)", .12)
                      + f'<g filter="url(#glass)" fill="url(#pf)" transform="translate({ISL / 2 - 280 * cpk:.2f} {ISL / 2 - 282 * cpk:.2f}) scale({cpk:.4f})">'
                        f'<circle cx="280" cy="168" r="128"/><path d="{BODY}"/></g>'),
    # CallControlButton's Speaker: frosted with a white glyph, or white with a dark glyph when on
    "island_speaker": speaker("#FFFFFF", .18, "url(#frost)", "url(#glass)"),
    "island_speaker_on": speaker("#FFFFFF", .92, "#111418", "none"),
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


RES.mkdir(parents=True, exist_ok=True)
for name, body in {"ic_launcher_background": PHONE_BG, "ic_launcher_foreground": HANDSET_FG,
                   "ic_contacts_background": CONTACTS_BG, "ic_contacts_foreground": PERSON_FG}.items():
    render(svg(body), RES / f"{name}.png", PX)
# Play wants the full square (it rounds the corners itself): the visible tile of both layers.
render(svg(PHONE_BG + HANDSET_FG, f"{O} {O} {T} {T}", 512), PLAY, 512)
for name, body in ISLAND.items():
    render(svg(body, f"0 0 {ISL} {ISL}", ISL), RES / f"{name}.png", ISL)
print("rendered to", RES, "and", PLAY)
