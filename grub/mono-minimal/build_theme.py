#!/usr/bin/env python3
"""
Build the 'mono-minimal' GRUB2 theme (clean black & white modern minimalist)
for Fedora + Windows dual boot, plus a pixel-accurate 1920x1080 preview image.
"""

import math
import os
import shutil
import struct
import subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent
THEME_DIR = ROOT / "mono-minimal"
ICONS_DIR = THEME_DIR / "icons"

GEIST_DIR = Path("/usr/share/fonts/vercel-geist-fonts")
GEIST_MONO_DIR = Path("/usr/share/fonts/vercel-geist-mono-fonts")

FONT_SPECS = [
    # (output_filename, source_otf, family_name_arg, size)
    ("geist_semibold_28.pf2", GEIST_DIR / "Geist-SemiBold.otf", "Geist SemiBold", 28),
    ("geist_medium_18.pf2",   GEIST_DIR / "Geist-Medium.otf",   "Geist Medium",   18),
    ("geist_regular_18.pf2",  GEIST_DIR / "Geist-Regular.otf",  "Geist Regular",  18),
    ("geist_mono_14.pf2",     GEIST_MONO_DIR / "GeistMono-Regular.otf", "Geist Mono", 14),
    ("geist_mono_13.pf2",     GEIST_MONO_DIR / "GeistMono-Regular.otf", "Geist Mono", 13),
    ("geist_mono_12.pf2",     GEIST_MONO_DIR / "GeistMono-Regular.otf", "Geist Mono", 12),
]


def read_pf2_name(pf2_path: Path) -> str:
    data = pf2_path.read_bytes()
    idx = data.find(b"NAME")
    if idx == -1:
        raise RuntimeError(f"No NAME section in {pf2_path}")
    ln = struct.unpack(">I", data[idx + 4 : idx + 8])[0]
    return data[idx + 8 : idx + 8 + ln].rstrip(b"\x00").decode("utf-8")


def build_fonts() -> dict[str, str]:
    font_names = {}
    for out_name, src, fam, size in FONT_SPECS:
        out_path = THEME_DIR / out_name
        cmd = [
            "grub2-mkfont",
            "-n", fam,
            "-s", str(size),
            "-o", str(out_path),
            str(src),
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            raise RuntimeError(f"grub2-mkfont failed for {src}: {res.stderr}")
        internal_name = read_pf2_name(out_path)
        font_names[out_name] = internal_name
        print(f"  [font] {out_name:24s} -> {internal_name!r}")
    return font_names


def save_9slice(img: Image.Image, prefix: str, edge: int):
    """Split a square (or rectangular) RGBA image into GRUB2 9-slice PNGs."""
    w, h = img.size
    e = edge
    slices = {
        "nw": (0,     0,     e,     e),
        "n":  (e,     0,     w - e, e),
        "ne": (w - e, 0,     w,     e),
        "w":  (0,     e,     e,     h - e),
        "c":  (e,     e,     w - e, h - e),
        "e":  (w - e, e,     w,     h - e),
        "sw": (0,     h - e, e,     h),
        "s":  (e,     h - e, w - e, h),
        "se": (w - e, h - e, w,     h),
    }
    for key, box in slices.items():
        img.crop(box).save(THEME_DIR / f"{prefix}_{key}.png")


def build_selection_box():
    """
    Inverted high-contrast pure white (#FFFFFF) rounded card (6px radius),
    rendered at 4x supersampling for razor-sharp anti-aliased corners.
    """
    scale = 4
    w, h = 40, 40
    edge = 8
    radius = 6

    big = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    d.rounded_rectangle(
        [0, 0, w * scale - 1, h * scale - 1],
        radius=radius * scale,
        fill=(255, 255, 255, 255),
    )
    img = big.resize((w, h), Image.Resampling.LANCZOS)
    save_9slice(img, "select", edge)
    print("  [ui]   select_*.png (6px radius solid #FFFFFF inverted bar)")


def build_terminal_box():
    """Minimal black terminal box with 1px #2E2E2E border."""
    w, h = 24, 24
    edge = 6
    img = Image.new("RGBA", (w, h), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w - 1, h - 1], fill=(0, 0, 0, 255), outline=(46, 46, 46, 255), width=1)
    save_9slice(img, "terminal_box", edge)
    print("  [ui]   terminal_box_*.png")


def build_solid_9slice(prefix: str, color: tuple[int, int, int, int]):
    px = Image.new("RGBA", (1, 1), color)
    for key in ("nw", "n", "ne", "w", "c", "e", "sw", "s", "se"):
        px.save(THEME_DIR / f"{prefix}_{key}.png")
    print(f"  [ui]   {prefix}_*.png")


def build_dividers():
    # Top accent divider: 1120x1 — 64px white rule + 1056px #2E2E2E hairline
    div = Image.new("RGBA", (1120, 1), (46, 46, 46, 255))
    for x in range(64):
        div.putpixel((x, 0), (255, 255, 255, 255))
    div.save(THEME_DIR / "divider_top.png")
    old_bot = THEME_DIR / "divider_bottom.png"
    if old_bot.exists():
        old_bot.unlink()
    print("  [ui]   divider_top.png (1120px)")


ICON_INK = (240, 240, 240, 255)  # #F0F0F0 crisp white glyph inside dark monochrome badge


def ss_icon(draw_fn, size: int = 28, glyph_size: int = 20, scale: int = 8) -> Image.Image:
    """
    Render a 28x28 monochrome dark tile (#0E0E0E with subtle 1px #2A2A2A rim)
    containing a centered crisp white OS glyph. Because GRUB2 reuses the same
    icon PNG for both selected and unselected rows, this dark badge stays crisp
    on pure #000000 AND pops cleanly with high contrast on the inverted #FFFFFF
    selected bar.
    """
    S = size * scale
    badge = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    bd = ImageDraw.Draw(badge)
    bd.rounded_rectangle(
        [0, 0, S - 1, S - 1],
        radius=5 * scale,
        fill=(14, 14, 14, 255),
        outline=(42, 42, 42, 255),
        width=scale,
    )

    G = glyph_size * scale
    glyph = Image.new("RGBA", (G, G), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glyph)
    # draw_fn expects logical 24-unit coordinate system scaled by k
    draw_fn(gd, G, G / 24.0)

    off = (S - G) // 2
    badge.alpha_composite(glyph, (off, off))
    return badge.resize((size, size), Image.Resampling.LANCZOS)


def draw_fedora(d: ImageDraw.ImageDraw, S: int, k: float):
    """
    Minimal monochrome Fedora emblem:
    Clean rounded teardrop silhouette (sharp bottom-left corner) + crisp stylized 'f' / infinity mark.
    """
    W = ICON_INK
    BG = (0, 0, 0, 0)
    pad = int(2.0 * k)
    stroke = int(2.1 * k)

    cx, cy = S // 2, S // 2
    r = (S // 2) - pad
    ir = r - stroke

    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=W)
    d.rounded_rectangle([cx - r, cy, cx, cy + r], radius=int(3.2 * k), fill=W)
    d.ellipse([cx - ir, cy - ir, cx + ir, cy + ir], fill=BG)
    d.rounded_rectangle([cx - ir, cy, cx, cy + ir], radius=int(1.8 * k), fill=BG)

    sw = int(2.1 * k)
    lr = int(2.7 * k)
    tx, ty = int(cx + 2.5 * k), int(cy - 2.5 * k)
    bx, by = int(cx - 2.5 * k), int(cy + 2.5 * k)

    d.arc([tx - lr, ty - lr, tx + lr, ty + lr], start=180, end=45, fill=W, width=sw)
    d.arc([bx - lr, by - lr, bx + lr, by + lr], start=0, end=225, fill=W, width=sw)
    d.line([(cx, ty), (cx, by)], fill=W, width=sw)
    d.line([(int(cx - 2.4 * k), cy), (int(cx + 2.6 * k), cy)], fill=W, width=int(1.9 * k))


def draw_windows(d: ImageDraw.ImageDraw, S: int, k: int):
    """Crisp modern Windows 11 4-pane outline grid matching Fedora & UEFI line weight."""
    W = ICON_INK
    sw = int(1.9 * k)
    pad = int(3.0 * k)
    r = int(1.8 * k)
    # Clean outer frame + center vertical & horizontal mullions
    d.rounded_rectangle([pad, pad, S - pad, S - pad], radius=r, outline=W, width=sw)
    mid = S // 2
    d.line([(mid, pad), (mid, S - pad)], fill=W, width=sw)
    d.line([(pad, mid), (S - pad, mid)], fill=W, width=sw)


def draw_efi(d: ImageDraw.ImageDraw, S: int, k: int):
    """Minimal geometric microchip / UEFI firmware icon with balanced optical weight."""
    W = ICON_INK
    sw = int(1.9 * k)
    m = int(5.4 * k)
    d.rounded_rectangle([m, m, S - m, S - m], radius=int(1.8 * k), outline=W, width=sw)
    cm = int(9.0 * k)
    d.rounded_rectangle([cm, cm, S - cm, S - cm], radius=int(0.8 * k), fill=W)
    pin_len = int(2.6 * k)
    pin_w = int(1.8 * k)
    offsets = [int(9.0 * k), int(S - 9.0 * k)]
    for pos in offsets:
        d.line([(pos, m - pin_len), (pos, m)], fill=W, width=pin_w)
        d.line([(pos, S - m), (pos, S - m + pin_len)], fill=W, width=pin_w)
        d.line([(m - pin_len, pos), (m, pos)], fill=W, width=pin_w)
        d.line([(S - m, pos), (S - m + pin_len, pos)], fill=W, width=pin_w)


def draw_linux_terminal(d: ImageDraw.ImageDraw, S: int, k: int):
    """Minimal rounded terminal frame with crisp >_ prompt."""
    W = ICON_INK
    sw = int(1.8 * k)
    px, py = int(2.5 * k), int(4.0 * k)
    d.rounded_rectangle([px, py, S - px, S - py], radius=int(2.2 * k), outline=W, width=sw)
    d.line(
        [(int(6.8 * k), int(9.2 * k)), (int(10.5 * k), int(12.0 * k)), (int(6.8 * k), int(14.8 * k))],
        fill=W,
        width=sw,
        joint="curve",
    )
    d.line(
        [(int(12.2 * k), int(14.8 * k)), (int(17.2 * k), int(14.8 * k))],
        fill=W,
        width=sw,
    )


def draw_os_generic(d: ImageDraw.ImageDraw, S: int, k: int):
    """Minimal geometric circle + core dot."""
    W = ICON_INK
    sw = int(1.8 * k)
    p = int(3.5 * k)
    d.ellipse([p, p, S - p, S - p], outline=W, width=sw)
    c = S // 2
    r = int(2.2 * k)
    d.ellipse([c - r, c - r, c + r, c + r], fill=W)


def draw_shutdown(d: ImageDraw.ImageDraw, S: int, k: int):
    """Minimal power icon."""
    W = ICON_INK
    sw = int(1.9 * k)
    p = int(4.0 * k)
    d.arc([p, p, S - p, S - p], start=310, end=230, fill=W, width=sw)
    c = S // 2
    d.line([(c, int(2.8 * k)), (c, int(11.5 * k))], fill=W, width=sw)


def draw_restart(d: ImageDraw.ImageDraw, S: int, k: int):
    """Minimal circular restart arrow."""
    W = ICON_INK
    sw = int(1.9 * k)
    p = int(4.0 * k)
    d.arc([p, p, S - p, S - p], start=30, end=315, fill=W, width=sw)
    ax, ay = int(17.5 * k), int(6.5 * k)
    d.polygon(
        [(ax, ay), (ax - int(4.2 * k), ay - int(0.8 * k)), (ax - int(0.8 * k), ay - int(4.2 * k))],
        fill=W,
    )


def build_icons():
    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    icon_map = {
        "fedora.png":    ss_icon(draw_fedora),
        "windows.png":   ss_icon(draw_windows),
        "efi.png":       ss_icon(draw_efi),
        "gnu-linux.png": ss_icon(draw_linux_terminal),
        "os.png":        ss_icon(draw_os_generic),
        "shutdown.png":  ss_icon(draw_shutdown),
        "restart.png":   ss_icon(draw_restart),
    }
    aliases = {
        "windows.png":   ["windows11.png", "windows10.png", "microsoft.png"],
        "efi.png":       ["uefi.png", "firmware.png", "settings.png", "uefi-firmware.png"],
        "gnu-linux.png": ["linux.png", "recovery.png", "kernel.png"],
        "os.png":        ["unknown.png", "gnu.png"],
    }
    for name, img in icon_map.items():
        img.save(ICONS_DIR / name)
        for alias in aliases.get(name, []):
            img.save(ICONS_DIR / alias)
    print(f"  [icon] generated {len(list(ICONS_DIR.glob('*.png')))} crisp 24x24 monochrome icons")


def write_theme_txt(font_names: dict[str, str]):
    f_title = font_names["geist_semibold_28.pf2"]
    f_sel   = font_names["geist_medium_18.pf2"]
    f_item  = font_names["geist_regular_18.pf2"]
    f_mono  = font_names["geist_mono_14.pf2"]
    f_hint  = font_names["geist_mono_13.pf2"]
    f_small = font_names["geist_mono_12.pf2"]

    content = f"""# Mono Minimal — Clean Black & White GRUB2 Theme
# Designed for Fedora + Windows Dual Boot (1920x1080 responsive)

title-text: ""
desktop-color: "#000000"

terminal-font: "{f_mono}"
terminal-box: "terminal_box_*.png"
terminal-left: "10%"
terminal-top: "12%"
terminal-width: "80%"
terminal-height: "76%"
terminal-border: "0"

# --- Main Title ---
+ label {{
    left = 50%-560
    top = 50%-224
    width = 1120
    height = 38
    align = "left"
    font = "{f_title}"
    color = "#FFFFFF"
    text = "Select Operating System"
}}

# --- Top Swiss Accent Hairline ---
+ image {{
    left = 50%-560
    top = 50%-174
    width = 1120
    height = 1
    file = "divider_top.png"
}}

# --- Boot Menu ---
+ boot_menu {{
    left = 50%-560
    top = 50%-148
    width = 1120
    height = 302

    item_font = "{f_item}"
    item_color = "#8A8A8A"
    selected_item_font = "{f_sel}"
    selected_item_color = "#000000"

    icon_width = 28
    icon_height = 28
    item_icon_space = 16
    item_height = 54
    item_padding = 8
    item_spacing = 8

    selected_item_pixmap_style = "select_*.png"

    scrollbar = true
    scrollbar_width = 3
    scrollbar_thumb = "scrollbar_thumb_*.png"
}}

# --- Auto-Boot Countdown Label ---
+ label {{
    id = "__timeout__"
    left = 50%-560
    top = 50%+178
    width = 1120
    height = 20
    align = "left"
    font = "{f_small}"
    color = "#909090"
    text = "AUTO-BOOT IN %ds"
}}

# --- Minimal 2px Linear Progress Bar ---
+ progress_bar {{
    id = "__timeout__"
    left = 50%-560
    top = 50%+204
    width = 1120
    height = 2
    show_text = false
    text = ""
    bar_style = "progress_bar_*.png"
    highlight_style = "progress_highlight_*.png"
}}

# --- Bottom Key Hints ---
+ label {{
    left = 50%-560
    top = 100%-56
    width = 1120
    height = 22
    align = "center"
    font = "{f_hint}"
    color = "#7D7D7D"
    text = "[↑↓] SELECT     [ENTER] BOOT     [E] EDIT     [C] CONSOLE"
}}
"""
    (THEME_DIR / "theme.txt").write_text(content, encoding="utf-8")
    print("  [cfg]  theme.txt written")


def draw_9slice_on(canvas: Image.Image, prefix: str, x: int, y: int, w: int, h: int):
    parts = {k: Image.open(THEME_DIR / f"{prefix}_{k}.png").convert("RGBA")
             for k in ("nw", "n", "ne", "w", "c", "e", "sw", "s", "se")}
    ew, eh = parts["nw"].size
    cw = max(1, w - 2 * ew)
    ch = max(1, h - 2 * eh)

    canvas.alpha_composite(parts["nw"], (x, y))
    canvas.alpha_composite(parts["n"].resize((cw, eh), Image.Resampling.NEAREST), (x + ew, y))
    canvas.alpha_composite(parts["ne"], (x + ew + cw, y))

    canvas.alpha_composite(parts["w"].resize((ew, ch), Image.Resampling.NEAREST), (x, y + eh))
    canvas.alpha_composite(parts["c"].resize((cw, ch), Image.Resampling.NEAREST), (x + ew, y + eh))
    canvas.alpha_composite(parts["e"].resize((ew, ch), Image.Resampling.NEAREST), (x + ew + cw, y + eh))

    canvas.alpha_composite(parts["sw"], (x, y + eh + ch))
    canvas.alpha_composite(parts["s"].resize((cw, eh), Image.Resampling.NEAREST), (x + ew, y + eh + ch))
    canvas.alpha_composite(parts["se"], (x + ew + cw, y + eh + ch))


def render_preview():
    """Render a pixel-faithful 1920x1080 preview using the exact generated theme assets."""
    W, H = 1920, 1080
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    d = ImageDraw.Draw(img)

    f_title = ImageFont.truetype(str(GEIST_DIR / "Geist-SemiBold.otf"), 28)
    f_sel   = ImageFont.truetype(str(GEIST_DIR / "Geist-Medium.otf"), 18)
    f_item  = ImageFont.truetype(str(GEIST_DIR / "Geist-Regular.otf"), 18)
    f_hint  = ImageFont.truetype(str(GEIST_MONO_DIR / "GeistMono-Regular.otf"), 13)
    f_small = ImageFont.truetype(str(GEIST_MONO_DIR / "GeistMono-Regular.otf"), 12)

    cx, cy = W // 2, H // 2
    col_x = cx - 560
    col_w = 1120

    # Title
    d.text((col_x, cy - 224), "Select Operating System", font=f_title, fill=(255, 255, 255, 255))

    # Top divider
    div_top = Image.open(THEME_DIR / "divider_top.png").convert("RGBA")
    img.alpha_composite(div_top, (col_x, cy - 174))

    # Boot menu items (realistic Fedora 45 + full 32-char rescue ID + Windows 11)
    entries = [
        ("fedora.png",  "Fedora Linux (7.3.4-300.fc45.x86_64) 45 (Workstation Edition)", True),
        ("fedora.png",  "Fedora Linux (7.3.1-300.fc45.x86_64) 45 (Workstation Edition)", False),
        ("fedora.png",  "Fedora Linux (0-rescue-8f4a2b1c9d3e7a6b5c4d3e2f1a0b9c8d) 45 (Workstation Edition)", False),
        ("windows.png", "Windows Boot Manager (on /dev/nvme0n1p1)", False),
        ("efi.png",     "UEFI Firmware Settings", False),
    ]

    menu_y = cy - 148
    item_h = 54
    item_sp = 8
    pad_left = 8 + 8  # select_w (8) + item_padding (8) = 16px

    for i, (icon_file, label, selected) in enumerate(entries):
        iy = menu_y + i * (item_h + item_sp)
        if selected:
            draw_9slice_on(img, "select", col_x, iy, col_w, item_h)
        icon = Image.open(ICONS_DIR / icon_file).convert("RGBA")
        icon_y = iy + (item_h - icon.height) // 2
        img.alpha_composite(icon, (col_x + pad_left, icon_y))

        font = f_sel if selected else f_item
        color = (0, 0, 0, 255) if selected else (138, 138, 138, 255)
        bbox = d.textbbox((0, 0), label, font=font)
        th = bbox[3] - bbox[1]
        ty = iy + (item_h - th) // 2 - bbox[1]
        d.text((col_x + pad_left + 28 + 16, ty), label, font=font, fill=color)

    # Timeout label
    d.text((col_x, cy + 178), "AUTO-BOOT IN 4s", font=f_small, fill=(144, 144, 144, 255))

    # Progress bar (at 80% remaining for 4s of 5s)
    bar_y = cy + 204
    d.rectangle([col_x, bar_y, col_x + col_w, bar_y + 1], fill=(46, 46, 46, 255))
    d.rectangle([col_x, bar_y, col_x + int(col_w * 0.80), bar_y + 1], fill=(255, 255, 255, 255))

    # Footer hints
    hints = "[↑↓] SELECT     [ENTER] BOOT     [E] EDIT     [C] CONSOLE"
    hw = d.textlength(hints, font=f_hint)
    d.text((cx - hw / 2, H - 56), hints, font=f_hint, fill=(125, 125, 125, 255))

    preview_path = ROOT / "preview.png"
    img.convert("RGB").save(preview_path)
    print(f"  [prev] {preview_path} (1920x1080)")


def main():
    THEME_DIR.mkdir(parents=True, exist_ok=True)
    print("Building Mono Minimal GRUB2 Theme...")
    font_names = build_fonts()
    build_selection_box()
    build_terminal_box()
    build_solid_9slice("progress_bar", (46, 46, 46, 255))
    build_solid_9slice("progress_highlight", (255, 255, 255, 255))
    build_solid_9slice("scrollbar_thumb", (64, 64, 64, 255))
    build_dividers()
    build_icons()
    write_theme_txt(font_names)
    render_preview()
    print("Done.")


if __name__ == "__main__":
    main()
