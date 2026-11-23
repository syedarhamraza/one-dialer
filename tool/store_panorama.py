"""Lays the Play Store screenshots out as one continuous panorama and cuts it into frames.

Reads the bare screens from `test/play_store_screenshots_test.dart` (build/play/, or build/play/it/
with LOCALE=it), draws the 8-frame strip as HTML, renders it with headless Chrome at 4x and writes
docs/play-store/<lang>/01.png ... 08.png (1080 x 1920, RGB) plus feature-graphic.png (1024 x 500).

  python tool/store_panorama.py            # English
  python tool/store_panorama.py it         # Italian
  python tool/store_panorama.py backgrounds  # writes the placeholder backgrounds

Backgrounds: docs/play-store/backgrounds/01..08 (1080 x 1920) and feature-graphic (1024 x 500), as
.png, .jpg or .webp. A frame with an image there uses it (cropped to fill); otherwise it gets the
built-in gradient. `backgrounds` writes those gradients there as placeholders, skipping files you have.
"""

import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
BACKGROUNDS = ROOT / 'docs' / 'play-store' / 'backgrounds'


def background(name):
    """CSS for the user's background image `name`, or '' for the built-in gradient."""
    for ext in ('png', 'jpg', 'jpeg', 'webp'):
        f = BACKGROUNDS / f'{name}.{ext}'
        if f.exists():
            return f'background:url({f.resolve().as_uri()}) center/cover;'
    return ''
FW, FH, GAP, SCALE = 270, 480, 8, 4  # one frame in CSS px; x4 = Play's 1080 x 1920
FRAMES = 8

# Headlines: plain words, and *one* accent in green serif italic. `giant` frames set one word huge.
HEADS = {
    'en': [
        ('Your calls,', 'in glass'),
        ('Pick up', 'in style'),
        ('Big, clear', 'controls'),
        ('giant', 'Type', '3', 'digits. Find', 'anyone'),
        ('Contacts,', 'sorted'),
        ('Block calls', 'before they ring'),
        ('Dual SIM,', 'done right'),
        ('giant', 'Free. No ads.', 'open', 'source', ''),
    ],
    'it': [
        ('Le tue chiamate,', 'in vetro'),
        ('Rispondi', 'con stile'),
        ('Comandi grandi', 'e chiari'),
        ('giant', 'Digita', '3', 'cifre. Trovi', 'tutti'),
        ('Contatti', 'in ordine'),
        ('Blocca', 'prima dello squillo'),
        ('Doppia SIM,', 'fatta bene'),
        ('giant', 'Gratis. Senza pubblicità.', 'open', 'source', ''),
    ],
}
FEATURE = {'en': ('Calls,', 'in glass'), 'it': ('Chiamate,', 'in vetro')}

GREEN = {0, 7}  # bookend frames; the rest are black

# Phones in strip CSS px: (screen, left, top, width, rotate degrees). Screens are 1:2.
PHONES = [
    ('1-recents', -40, 170, 250, -4),
    ('4-incoming', 196, 210, 200, 5),
    ('5-in-call', 596, 200, 210, 0),
    ('2-keypad', 930, 280, 220, -3),
    ('3-contacts', 1170, 190, 205, 3),
    ('6-blocking', 1440, 196, 210, 0),
    ('7-dual-sim', 1722, 210, 210, -3),
    ('8-glass', 2010, 290, 230, 6),
]

# Pieces of a screen pulled out and shown bigger: (screen, crop x, y, w, h in screen px, left, top, scale).
POPS = [
    ('4-incoming', 730, 1690, 220, 220, 372, 360, .36, True),   # Answer button
    ('5-in-call', 40, 1380, 1000, 240, 562, 352, .258, False),     # call controls
    ('2-keypad', 30, 360, 760, 190, 852, 232, .33, False),       # T9 match
    ('3-contacts', 990, 780, 90, 800, 1344, 180, .34, False),    # A-Z index
    ('6-blocking', 30, 270, 1020, 230, 1396, 150, .254, False),    # block rule
    ('7-dual-sim', 20, 940, 620, 320, 1690, 360, .38, False),    # SIM chooser
]


def chrome():
    for p in [os.environ.get('CHROME', ''),
              r'C:\Program Files\Google\Chrome\Application\chrome.exe',
              r'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe',
              shutil.which('google-chrome') or '', shutil.which('chromium') or '']:
        if p and Path(p).exists():
            return p
    sys.exit('No Chrome or Edge found; set CHROME to its path.')


def head_html(h):
    if h[0] == 'giant':
        _, top, big, rest, accent = h
        em = f' <em>{accent}</em>' if accent else ''
        return f'<h2 class="sm">{top}</h2><div class="giant">{big}</div><h2 class="sm">{rest}{em}</h2>'
    plain, accent = h
    return f'<h2>{plain}<br><em>{accent}</em></h2>'


STYLE = """
:root { --ink:#050806; --paper:#f2f5f1; --green:#00b833; --green-deep:#078a2c; --red:#ff6b5e; --gapc:#000; }
* { box-sizing:border-box; }
html, body { margin:0; background:var(--gapc); color:var(--paper); }
.strip { position:relative; overflow:hidden; }
.f { position:absolute; top:0; width:%(FW)dpx; height:%(FH)dpx; padding:26px 20px 0; }
.f.green { background:radial-gradient(120%% 80%% at 20%% 0%%, #19d14a, var(--green-deep)); }
.f.black { background:radial-gradient(90%% 60%% at 50%% 100%%, #0d2a16, var(--ink) 70%%); }
h2 { font-family:"Bricolage Grotesque", "Arial Black", sans-serif; font-weight:800; font-size:33px; line-height:.98;
  letter-spacing:-.02em; margin:0; position:relative; z-index:3; }
h2.sm { font-size:25px; }
h2 em, .giant { font-family:"Instrument Serif", Georgia, serif; font-style:italic; font-weight:400; letter-spacing:0; color:var(--green); }
h2 em { font-size:1.18em; }
.green h2 em, .green .giant { color:var(--ink); }
.f5 h2 em { color:var(--red); }
.giant { font-size:190px; line-height:.8; margin:-6px 0 -10px; position:relative; z-index:3; }
.f7 .giant { font-size:118px; margin:2px 0 8px -4px; }
.ph { position:absolute; z-index:2; border-radius:28px; padding:5px; background:#1c211d;
  box-shadow:0 0 0 1px #2c332e, 0 30px 60px rgba(0,0,0,.6); }
.ph img { display:block; width:100%%; border-radius:23px; }
.pop { position:absolute; z-index:4; border-radius:22px; background-repeat:no-repeat;
  box-shadow:0 0 0 1px rgba(255,255,255,.08), 0 18px 40px rgba(0,0,0,.6); }
.pop.round { border-radius:50%%; box-shadow:0 0 40px rgba(0,200,60,.55); }
.gap { position:absolute; top:0; width:%(GAP)dpx; height:%(FH)dpx; background:var(--gapc); z-index:5; }
.fg { position:relative; width:1024px; height:500px; overflow:hidden;
  background:radial-gradient(120%% 90%% at 15%% 10%%, #19d14a, var(--green-deep)); }
.fg .name { position:absolute; left:64px; top:150px; display:flex; align-items:center; gap:22px;
  font:800 62px "Bricolage Grotesque", sans-serif; letter-spacing:-.02em; color:var(--paper); }
.fg .name img { width:96px; height:96px; border-radius:24px; }
.fg h2 { position:absolute; left:64px; top:270px; font-size:58px; color:var(--ink); }
.fg h2 em { color:var(--paper); }
""" % dict(FW=FW, FH=FH, GAP=GAP)

FONTS = ('<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:'
         'opsz,wght@12..96,800&family=Instrument+Serif:ital@1&display=swap">')


def strip_html(lang, shots, bare=False):
    x = lambda i: i * (FW + GAP)
    w = x(FRAMES) - GAP
    out = [f'<div class="strip" style="width:{w}px;height:{FH}px">']
    for i, h in enumerate(HEADS[lang]):
        bg = 'green' if i in GREEN else 'black'
        if bare:
            out.append(f'<section class="f {bg}" style="left:{x(i)}px"></section>')
            continue
        out.append(f'<section class="f {bg} f{i}" style="left:{x(i)}px;{background(f"{i + 1:02d}")}">'
                   f'{head_html(h)}</section>')
    for name, l, t, pw, r in [] if bare else PHONES:
        out.append(f'<div class="ph" style="left:{l}px;top:{t}px;width:{pw}px;transform:rotate({r}deg)">'
                   f'<img src="{shots[name]}"></div>')
    for name, cx, cy, cw, ch, l, t, s, round_ in [] if bare else POPS:
        out.append(f'<div class="pop{" round" if round_ else ""}" style="left:{l}px;top:{t}px;'
                   f'width:{cw * s:.1f}px;height:{ch * s:.1f}px;background-image:url({shots[name]});'
                   f'background-size:{1080 * s:.1f}px {2160 * s:.1f}px;background-position:{-cx * s:.1f}px {-cy * s:.1f}px"></div>')
    for i in range(1, FRAMES):
        out.append(f'<div class="gap" style="left:{x(i) - GAP}px"></div>')
    out.append('</div>')
    return w, ''.join(out)


def feature_html(lang, shots, icon):
    plain, accent = FEATURE[lang]
    phones = [('1-recents', 600, 60, 210, -6), ('4-incoming', 790, 120, 210, 6)]
    ph = ''.join(f'<div class="ph" style="left:{l}px;top:{t}px;width:{pw}px;transform:rotate({r}deg)">'
                 f'<img src="{shots[n]}"></div>' for n, l, t, pw, r in phones)
    return (f'<div class="fg" style="{background("feature-graphic")}"><div class="name"><img src="{icon}">One Dialer</div>'
            f'<h2>{plain} <em>{accent}</em></h2>{ph}</div>')


def render(html, w, h, scale, png):
    with tempfile.TemporaryDirectory() as tmp:
        page = Path(tmp, 'page.html')
        page.write_text(f'<!doctype html><meta charset="utf-8">{FONTS}<style>{STYLE}</style>{html}', encoding='utf-8')
        subprocess.run([chrome(), '--headless=new', '--disable-gpu', '--hide-scrollbars', '--allow-file-access-from-files',
                        f'--user-data-dir={tmp}/profile', f'--window-size={w},{h}', f'--force-device-scale-factor={scale}',
                        '--virtual-time-budget=8000', f'--screenshot={png}', page.as_uri()],
                       check=True, capture_output=True)


def cut(strip, w, out, names):
    """Cuts the rendered strip into one 24-bit PNG per frame (Play takes no alpha)."""
    img = Image.open(strip).convert('RGB')
    assert img.size == (w * SCALE, FH * SCALE), img.size
    for i, name in enumerate(names):
        left = i * (FW + GAP) * SCALE
        if name:
            img.crop((left, 0, left + FW * SCALE, FH * SCALE)).save(out / name)
    strip.unlink()


def placeholders():
    BACKGROUNDS.mkdir(parents=True, exist_ok=True)
    have = {f.stem for f in BACKGROUNDS.iterdir()}
    names = [None if f'{i + 1:02d}' in have else f'{i + 1:02d}.png' for i in range(FRAMES)]
    w, html = strip_html('en', {}, bare=True)
    render(html, w, FH, SCALE, BACKGROUNDS / 'strip.png')
    cut(BACKGROUNDS / 'strip.png', w, BACKGROUNDS, names)
    if 'feature-graphic' not in have:
        fg = BACKGROUNDS / 'feature-graphic.png'
        render('<div class="fg"></div>', 1024, 500, 1, fg)
        Image.open(fg).convert('RGB').save(fg)
    print(f'Placeholder backgrounds are in {BACKGROUNDS}; replace any of them with your own.')


def main():
    lang = sys.argv[1] if len(sys.argv) > 1 else 'en'
    if lang == 'backgrounds':
        return placeholders()
    src = ROOT / 'build' / 'play' / ('' if lang == 'en' else lang)
    shots = {p.stem: p.resolve().as_uri() for p in src.glob('[0-9]-*.png')}
    missing = {n for n, *_ in PHONES} - shots.keys()
    if missing:
        sys.exit(f'Missing {sorted(missing)} in {src}: run test/play_store_screenshots_test.dart first.')
    out = ROOT / 'docs' / 'play-store' / lang
    out.mkdir(parents=True, exist_ok=True)

    w, html = strip_html(lang, shots)
    strip = out / 'strip.png'
    render(html, w, FH, SCALE, strip)
    cut(strip, w, out, [f'{i + 1:02d}.png' for i in range(FRAMES)])

    fg = out / 'feature-graphic.png'
    render(feature_html(lang, shots, (ROOT / 'docs' / 'play-icon.png').resolve().as_uri()), 1024, 500, 1, fg)
    Image.open(fg).convert('RGB').save(fg)
    print(f'Wrote {FRAMES} frames and the feature graphic to {out}')


if __name__ == '__main__':
    main()
