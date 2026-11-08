"""Palette from a wallpaper: ImageMagick quantizes the image, then colors are picked in HSL.

The background is very dark with a tint of the image's main hue; the accents are the
most vivid visible colors brought to a readable lightness. Terminal colors are the
standard ANSI hues, slightly shifted towards the wallpaper's tone.
"""

import os
import colorsys
import re
import subprocess


def _hex(h, l, s):
    r, g, b = colorsys.hls_to_rgb(h % 1.0, max(0, min(1, l)), max(0, min(1, s)))
    return "#{:02x}{:02x}{:02x}".format(round(r * 255), round(g * 255), round(b * 255))


def _hue_dist(a, b):
    d = abs(a - b) % 1.0
    return min(d, 1 - d)


def _colors(image):
    """[(share, h, l, s)] — up to 16 main colors of the image."""
    out = subprocess.run(
        ["magick", f"{image}[0]", "-alpha", "off", "-depth", "8", "-resize", "160x160", "-colors", "16", "-format", "%c", "histogram:info:-"],
        capture_output=True, text=True, check=True).stdout
    found = []
    for count, hexcode in re.findall(r"^\s*(\d+):.*?(#[0-9A-Fa-f]{6})", out, re.M):
        r, g, b = (int(hexcode[i:i + 2], 16) / 255 for i in (1, 3, 5))
        h, l, s = colorsys.rgb_to_hls(r, g, b)
        found.append((int(count), h, l, s))
    total = sum(c for c, *_ in found) or 1
    return [(c / total, h, l, s) for c, h, l, s in found]


def generate(image):
    colors = _colors(image)

    # The main hue — by area, but gray patches barely vote
    base_hue = max(colors, key=lambda c: c[0] * (0.15 + c[3]))[1]

    # Accent candidates: visible and saturated, not near-black/white
    vivid = sorted((c for c in colors if c[3] > 0.18 and 0.12 < c[2] < 0.92),
                   key=lambda c: c[3] * (0.4 + c[0] ** 0.5), reverse=True)
    accents = []
    for c in vivid:
        if all(_hue_dist(c[1], a) > 0.07 for a in accents):
            accents.append(c[1])
    mono = not accents

    # Not enough accents — fill in by rotating around the color wheel from the first
    first = accents[0] if accents else base_hue
    while len(accents) < 3:
        accents.append((first + [0.0, 0.12, -0.12][len(accents)]) % 1.0)

    bg_s = 0.04 if mono else 0.32      # background saturation
    acc_s = 0.06 if mono else 0.75     # accent saturation

    def ansi(hue, light):
        # the standard ANSI hue, pulled towards the wallpaper's tone
        h = hue + 0.15 * ((base_hue - hue + 0.5) % 1.0 - 0.5)
        return _hex(h, light, 0.12 if mono else 0.55)

    p = {
        "name": "From wallpaper",
        "void":    _hex(base_hue, 0.025, bg_s),
        "base":    _hex(base_hue, 0.055, bg_s),
        "surface": _hex(base_hue, 0.095, bg_s),
        "overlay": _hex(base_hue, 0.155, bg_s * 0.9),
        "muted":   _hex(base_hue, 0.33, bg_s * 0.6),
        "subtle":  _hex(base_hue, 0.55, bg_s * 0.45),
        "text":    _hex(base_hue, 0.84, bg_s * 0.5),
        "bright":  _hex(base_hue, 0.94, bg_s * 0.6),
        "blue":    _hex(accents[0], 0.68, acc_s),
        "violet":  _hex(accents[1], 0.70, acc_s * 0.9),
        "cyan":    _hex(accents[2], 0.72, acc_s * 0.8),
        "rose":    _hex(0.97, 0.66, 0.75),
        "selection": _hex(accents[0], 0.22, bg_s + 0.1),
        "term0":  _hex(base_hue, 0.095, bg_s),
        "term8":  _hex(base_hue, 0.33, bg_s * 0.6),
        "term7":  _hex(base_hue, 0.75, bg_s * 0.4),
        "term15": _hex(base_hue, 0.94, bg_s * 0.6),
    }
    for n, hue in ((1, 0.98), (2, 0.38), (3, 0.12), (4, 0.6), (5, 0.8), (6, 0.5)):
        p[f"term{n}"] = ansi(hue, 0.64)
        p[f"term{n + 8}"] = ansi(hue, 0.74)

    lines = [f"# GENERATED from the wallpaper: {os.path.basename(image)}", ""]
    lines += [f"{k} = {v}" for k, v in p.items()]
    return "\n".join(lines) + "\n"
