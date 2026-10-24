"""Renders the launcher icons (Phone, Contacts) and the Play Store icon from SVG.

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


def glass_filter(fid):
    """Figma's effects on the glyphs: a deep green drop shadow, a white bevel top-left, a green one bottom-right."""
    alpha = '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>'
    inner = lambda dx, dy, blur, c, a, prev, out: (
        alpha + f'<feOffset dx="{dx}" dy="{dy}"/><feGaussianBlur stdDeviation="{blur / 2}"/>'
        '<feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/>'
        f'<feColorMatrix type="matrix" values="{rgba(c, a)}"/><feBlend in2="{prev}" result="{out}"/>')
    return (
        f'<filter id="{fid}" x="0" y="0" width="{L}" height="{L}" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">'
        + alpha + '<feOffset dy="22"/><feGaussianBlur stdDeviation="22"/>'
        f'<feColorMatrix type="matrix" values="{rgba("#00451F", .38)}" result="drop"/>'
        '<feBlend in="SourceGraphic" in2="drop" result="shape"/>'
        + inner(-4, 8, 10, "#FFFFFF", 1, "shape", "bevel")
        + inner(6, -14, 22, "#1FA85C", .6, "bevel", "out")
        + "</filter>")


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
F = (0.59 * T - 2 * W) * 24 / 18
hk, ho = F / 24, O + (T - F) / 2
HANDSET_FG = (f'<defs>{FROST}{glass_filter("glass")}</defs><g filter="url(#glass)"><g opacity=".88">'
              f'<path transform="translate({ho:.2f} {ho:.2f}) scale({hk:.4f})" d="{HANDSET}" fill="url(#frost)" '
              f'stroke="url(#frost)" stroke-width="{2 * W / hk:.3f}" stroke-linejoin="round"/></g></g>')

# The person is 54% of the tile tall, a little left of centre to clear the spine.
pk = 0.54 * T / 484
px, py = O + 0.47 * T - 280 * pk, O + T / 2 - 282 * pk
PERSON_FG = (f'<defs>{FROST}{glass_filter("glass")}</defs><g filter="url(#glass)"><g opacity=".88" fill="url(#frost)" '
             f'transform="translate({px:.2f} {py:.2f}) scale({pk:.4f})"><circle cx="280" cy="168" r="128"/><path d="{BODY}"/></g></g>')

PHONE_BG = tile_bg("#4DEA8E", "#04B457")
CONTACTS_BG = tile_bg("#3FE3A0", "#00A86B", SPINE)


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
print("rendered to", RES, "and", PLAY)
