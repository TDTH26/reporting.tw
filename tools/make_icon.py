"""Draw the app icon (Play Store 512x512 + Android launcher mipmaps).

    cd backend && uv run python ../tools/make_icon.py
Informant app: brand blue. Field app (src/field/res): dark navy, so officers can tell the two apart.
"""

import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
ANDROID = ROOT / "app/apps/uavr/android/app/src"
S = 2048  # draw large, downsample for smooth edges
WHITE = (255, 255, 255, 255)
RED = (229, 57, 53, 255)


def gradient(top, bottom):
    img = Image.new("RGBA", (S, S))
    d = ImageDraw.Draw(img)
    for y in range(S):
        t = y / (S - 1)
        d.line([(0, y), (S, y)], fill=tuple(round(a + (b - a) * t) for a, b in zip(top, bottom)) + (255,))
    return img


def brush(d: ImageDraw.ImageDraw, pts, width: float, fill) -> None:
    """Round-capped stroke without the notches ImageDraw.line leaves on dense polylines."""
    r = width / 2
    for (x1, y1), (x2, y2) in zip(pts, pts[1:]):
        steps = max(1, int(math.hypot(x2 - x1, y2 - y1) / 3))
        for k in range(steps + 1):
            x, y = x1 + (x2 - x1) * k / steps, y1 + (y2 - y1) * k / steps
            d.ellipse([x - r, y - r, x + r, y + r], fill=fill)


def icon(top, bottom, background: bool = True) -> Image.Image:
    """The full icon, or (background=False) only the symbols on transparency for adaptive icons."""
    img = gradient(top, bottom) if background else Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S * 0.42

    # Sighting reticle (semi-transparent layer): ring with four ticks.
    ring = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    g = ImageDraw.Draw(ring)
    r = S * 0.30
    w = round(S * 0.02)
    g.ellipse([cx - r, cy - r, cx + r, cy + r], outline=WHITE, width=w)
    for a in (0, 90, 180, 270):
        c, s_ = math.cos(math.radians(a)), math.sin(math.radians(a))
        g.line(
            [
                (cx + c * (r - S * 0.045), cy + s_ * (r - S * 0.045)),
                (cx + c * (r + S * 0.045), cy + s_ * (r + S * 0.045)),
            ],
            fill=WHITE,
            width=w,
        )
    ring.putalpha(ring.getchannel("A").point(lambda v: v * 150 // 255))
    img.alpha_composite(ring)

    d = ImageDraw.Draw(img)
    # Quadcopter seen from above: X arms, rotor rings, body.
    arm = S * 0.15
    for a in (45, 135, 225, 315):
        ex, ey = cx + math.cos(math.radians(a)) * arm, cy + math.sin(math.radians(a)) * arm
        brush(d, [(cx, cy), (ex, ey)], S * 0.034, WHITE)
        rr = S * 0.068
        d.ellipse([ex - rr, ey - rr, ex + rr, ey + rr], outline=WHITE, width=round(S * 0.026))
        hub = S * 0.017
        d.ellipse([ex - hub, ey - hub, ex + hub, ey + hub], fill=WHITE)
    body = S * 0.06
    d.rounded_rectangle([cx - body, cy - body, cx + body, cy + body], radius=S * 0.022, fill=WHITE)

    # Sea: two waves below the reticle.
    for i, yy in enumerate((S * 0.83, S * 0.90)):
        pts = [
            (x, yy + math.sin((x - S * 0.18) / S * math.pi * 6) * S * 0.016)
            for x in range(round(S * 0.20), round(S * 0.80) + 1, 6)
        ]
        brush(d, pts, S * 0.026, (255, 255, 255, 255) if i == 0 else (205, 220, 240, 255))

    # Alert dot on the reticle's upper right.
    ar = S * 0.07
    ax, ay = cx + math.cos(math.radians(-45)) * r, cy + math.sin(math.radians(-45)) * r
    gap = S * 0.016
    d.ellipse([ax - ar - gap, ay - ar - gap, ax + ar + gap, ay + ar + gap], fill=top + (255,))
    d.ellipse([ax - ar, ay - ar, ax + ar, ay + ar], fill=RED)
    return img


SIZES = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}


def rounded(img: Image.Image, px: int) -> Image.Image:
    small = img.resize((px, px), Image.LANCZOS)
    mask = Image.new("L", (px * 4, px * 4), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, px * 4 - 1, px * 4 - 1], radius=px * 4 * 0.22, fill=255)
    small.putalpha(mask.resize((px, px), Image.LANCZOS))
    return small


def write_launcher(img: Image.Image, flavor: str) -> None:
    for name, px in SIZES.items():
        out = ANDROID / flavor / "res" / f"mipmap-{name}" / "ic_launcher.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        rounded(img, px).save(out, optimize=True)


ADAPTIVE = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
ADAPTIVE_XML = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
    <monochrome android:drawable="@mipmap/ic_launcher_monochrome" />
</adaptive-icon>
"""


def write_adaptive(top, bottom, flavor: str) -> None:
    """Android 8+ icon layers: launchers crop them to their own shape, so symbols stay in the 66% safe zone."""
    symbols = icon(top, bottom, background=False)
    fg = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    inner = round(S * 0.64)
    fg.alpha_composite(symbols.resize((inner, inner), Image.LANCZOS), ((S - inner) // 2, (S - inner) // 2))
    mono = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    mono.putalpha(fg.getchannel("A"))
    bg = gradient(top, bottom)
    res = ANDROID / flavor / "res"
    for name, px in ADAPTIVE.items():
        d = res / f"mipmap-{name}"
        d.mkdir(parents=True, exist_ok=True)
        fg.resize((px, px), Image.LANCZOS).save(d / "ic_launcher_foreground.png", optimize=True)
        bg.resize((px, px), Image.LANCZOS).convert("RGB").save(d / "ic_launcher_background.png", optimize=True)
        mono.resize((px, px), Image.LANCZOS).save(d / "ic_launcher_monochrome.png", optimize=True)
    (res / "mipmap-anydpi-v26").mkdir(parents=True, exist_ok=True)
    (res / "mipmap-anydpi-v26" / "ic_launcher.xml").write_text(ADAPTIVE_XML)


def main() -> None:
    informant = icon((33, 99, 196), (18, 52, 110))
    field = icon((30, 41, 59), (10, 15, 26))
    store = ROOT / "dist"
    store.mkdir(exist_ok=True)
    informant.resize((512, 512), Image.LANCZOS).convert("RGB").save(
        store / "play-icon-informant-512.png", optimize=True
    )
    field.resize((512, 512), Image.LANCZOS).convert("RGB").save(store / "play-icon-field-512.png", optimize=True)
    write_launcher(informant, "main")
    write_launcher(field, "field")
    write_adaptive((33, 99, 196), (18, 52, 110), "main")
    write_adaptive((30, 41, 59), (10, 15, 26), "field")
    # Console logo (left menu).
    rounded(informant, 128).save(ROOT / "app/packages/feature_agency/assets/app_icon.png", optimize=True)
    # Web favicon / PWA icons use the informant icon.
    web = ROOT / "app/apps/uavr/web"
    if (web / "icons").exists():
        for px in (192, 512):
            informant.resize((px, px), Image.LANCZOS).convert("RGB").save(
                web / "icons" / f"Icon-{px}.png", optimize=True
            )
            rounded(informant, px).save(web / "icons" / f"Icon-maskable-{px}.png", optimize=True)
        informant.resize((32, 32), Image.LANCZOS).save(web / "favicon.png")
    print("ok")


if __name__ == "__main__":
    main()
