
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path
import math

# ------------- Config -------------
TITLE = "Allah Kavramı – Tarihsel Gelişim ve Yorumlar"
OUTPUT = "allah_kavrami_modern_infografik.png"
SIZE = (1600, 1000)  # width, height
MARGIN = 60
GAP = 26
RADIUS = 28

# Card content (title, bullets, gradient)
CARDS = [
    {
        "title": "📜 Dil Kökeni",
        "bullets": [
            "Sami dillerde 'El/Ilah' → Tanrı",
            "İbranice: Eloah/Elohim",
            "Aramice: Elaha/Alaha",
            "Süryanice: Alāhā",
        ],
        "grad": ((35, 99, 235), (96, 165, 250)),  # blue → light blue
        "icon": "scroll",
    },
    {
        "title": "🏺 Cahiliye",
        "bullets": [
            "Allah: Yüce Yaratıcı",
            "Putlar: aracı",
        ],
        "grad": ((5, 150, 105), (74, 222, 128)),  # green tones
        "icon": "vase",
    },
    {
        "title": "📖 Kur’ân",
        "bullets": [
            "Tevhid, şirk reddi",
            "'Huve' (O) zamiri",
            "Esmaü’l-Hüsna (sıfatlar)",
        ],
        "grad": ((245, 158, 11), (253, 186, 116)),  # orange
        "icon": "book",
    },
    {
        "title": "🕌 Kelam",
        "bullets": [
            "Eş'arî & Maturidî",
            "'Allah' özel isim",
        ],
        "grad": ((139, 92, 246), (196, 181, 253)),  # purple
        "icon": "mosque",
    },
    {
        "title": "🌿 Tasavvuf",
        "bullets": [
            "İsim sembol, asıl O",
            "İsim–Müsemma ayrımı",
        ],
        "grad": ((236, 72, 153), (244, 114, 182)),  # pink
        "icon": "leaf",
    },
    {
        "title": "🧠 Felsefe",
        "bullets": [
            "Farabi, İbn Sina",
            "İsim beşer için",
        ],
        "grad": ((55, 65, 81), (156, 163, 175)),  # gray
        "icon": "brain",
    },
    {
        "title": "🌍 Modern",
        "bullets": [
            "Kültürel adlandırma",
            "Mutlak aynı hakikat",
        ],
        "grad": ((16, 185, 129), (110, 231, 183)),  # teal/green
        "icon": "globe",
    },
    {
        "title": "❤️ Senin Görüşün",
        "bullets": [
            "El-İlah telaffuzu",
            "Yegâne olana isim verilmez",
            "'O' demek yeter",
        ],
        "grad": ((220, 38, 38), (252, 165, 165)),  # red
        "icon": "heart",
    },
]

# ------------- Drawing helpers -------------
def load_font(size, bold=False):
    # Try DejaVuSans (bundled with Pillow), fallback to default
    try:
        name = "DejaVuSans-Bold.ttf" if bold else "DejaVuSans.ttf"
        return ImageFont.truetype(name, size=size)
    except Exception:
        return ImageFont.load_default()

def rounded_rect_mask(size, radius):
    w, h = size
    mask = Image.new("L", size, 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, w, h), radius=radius, fill=255)
    return mask

def linear_gradient(size, c1, c2, horizontal=False):
    """Return a gradient image from c1 to c2."""
    w, h = size
    base = Image.new("RGB", size, c1)
    top = Image.new("RGB", size, c2)
    mask = Image.new("L", size)
    md = ImageDraw.Draw(mask)
    if horizontal:
        for x in range(w):
            val = int(255 * (x / max(1, w - 1)))
            md.line([(x, 0), (x, h)], fill=val)
    else:
        for y in range(h):
            val = int(255 * (y / max(1, h - 1)))
            md.line([(0, y), (w, y)], fill=val)
    return Image.composite(top, base, mask)

def drop_shadow(img, offset=(0, 6), radius=12, opacity=120):
    # Create shadow via gaussian blur on alpha mask
    shadow = Image.new("RGBA", (img.width + abs(offset[0]) + radius*2, img.height + abs(offset[1]) + radius*2), (0,0,0,0))
    sx = radius
    sy = radius
    shadow_mask = Image.new("L", (img.width, img.height), 0)
    shadow_mask.paste(img.split()[-1], (0,0))
    shadow_draw = Image.new("L", shadow.size, 0)
    shadow_draw.paste(shadow_mask, (sx, sy))
    shadow_blur = Image.fromarray(shadow_draw).filter(ImageFilter.GaussianBlur(radius=radius))
    rgba = Image.new("RGBA", shadow.size, (0,0,0,0))
    rgba.paste((0,0,0,opacity), mask=shadow_blur)
    return rgba

def draw_icon(draw, box, kind, fill=(255,255,255)):
    # Simple vector-like icons
    x0, y0, x1, y1 = box
    w = x1 - x0; h = y1 - y0
    cx = x0 + w/2; cy = y0 + h/2
    if kind == "scroll":
        # scroll: a rectangle with header/footer
        draw.rounded_rectangle([x0+8, y0+12, x1-8, y1-12], radius=10, outline=fill, width=3)
        draw.line([x0+20, y0+28, x1-20, y0+28], fill=fill, width=2)
        draw.line([x0+20, y1-28, x1-20, y1-28], fill=fill, width=2)
    elif kind == "vase":
        # amphora-like silhouette
        draw.polygon([
            (cx, y0+10), (x1-18, y0+18), (x1-22, y0+32),
            (x1-30, y0+46), (x1-40, y1-16), (cx, y1-8),
            (x0+40, y1-16), (x0+30, y0+46), (x0+22, y0+32), (x0+18, y0+18)
        ], outline=fill)
    elif kind == "book":
        # book: closed book with spine
        draw.rectangle([x0+10, y0+12, x1-12, y1-12], outline=fill, width=3)
        draw.line([cx, y0+12, cx, y1-12], fill=fill, width=3)
    elif kind == "mosque":
        # simple dome + base
        draw.arc([x0+14, y0+10, x1-14, y1-4], 200, -20, fill=fill, width=3)
        draw.line([x0+20, y1-14, x1-20, y1-14], fill=fill, width=3)
        # minaret
        draw.line([x1-24, y0+12, x1-24, y1-14], fill=fill, width=3)
    elif kind == "leaf":
        # leaf shape
        draw.polygon([
            (cx, y0+6), (x1-10, cy), (cx, y1-6), (x0+10, cy)
        ], outline=fill)
        draw.line([cx, y0+6, cx, y1-6], fill=fill, width=2)
    elif kind == "brain":
        # circle-ish + squiggles
        draw.ellipse([x0+10, y0+10, x1-10, y1-10], outline=fill, width=3)
        draw.line([x0+20, cy, x1-20, cy], fill=fill, width=2)
        draw.arc([x0+18, y0+18, x1-18, y1-18], 200, 340, fill=fill, width=2)
    elif kind == "globe":
        draw.ellipse([x0+8, y0+8, x1-8, y1-8], outline=fill, width=3)
        draw.line([cx, y0+8, cx, y1-8], fill=fill, width=2)
        draw.arc([x0+8, y0+20, x1-8, y1-20], 0, 180, fill=fill, width=2)
        draw.arc([x0+8, y0+30, x1-8, y1-30], 180, 360, fill=fill, width=2)
    elif kind == "heart":
        # heart polygon approximation
        draw.polygon([
            (cx, y1-8),
            (x1-8, cy),
            (cx, y0+12),
            (x0+8, cy)
        ], outline=fill)
    else:
        # default: dot
        draw.ellipse([cx-6, cy-6, cx+6, cy+6], fill=fill)

def text_wrap(draw, text, font, max_w):
    words = text.split()
    lines = []
    line = ""
    for w in words:
        test = (line + " " + w).strip()
        if draw.textlength(test, font=font) <= max_w:
            line = test
        else:
            if line:
                lines.append(line)
            line = w
    if line:
        lines.append(line)
    return lines

def draw_card(base, box, title, bullets, grad, icon_kind, fonts):
    x0, y0, x1, y1 = box
    w = x1 - x0; h = y1 - y0

    # Gradient card with rounded corners
    grad_img = linear_gradient((w, h), grad[0], grad[1], horizontal=False).convert("RGBA")
    mask = rounded_rect_mask((w, h), RADIUS)
    card_rgba = Image.new("RGBA", (w, h), (0,0,0,0))
    card_rgba.paste(grad_img, (0,0), mask=mask)

    # Shadow
    sh = Image.new("RGBA", card_rgba.size, (0,0,0,0))
    sh_mask = rounded_rect_mask((w, h), RADIUS)
    sh_img = Image.new("RGBA", (w, h), (0,0,0,0))
    sh_img.putalpha(sh_mask)
    shadow = sh_img.filter(ImageFilter.GaussianBlur(radius=14))
    base.alpha_composite(Image.new("RGBA", base.size, (0,0,0,0)), (0,0))
    base.paste((0,0,0,70), (x0+2, y0+6, x1+2, y1+6), shadow.split()[-1])

    # Paste card
    base.paste(card_rgba, (x0, y0), card_rgba)

    d = ImageDraw.Draw(base)
    title_font = fonts["title"]
    body_font = fonts["body"]

    # Icon area
    icon_box = (x0+18, y0+14, x0+74, y0+70)
    draw_icon(d, icon_box, icon_kind, fill=(255,255,255))

    # Title
    d.text((x0+86, y0+18), title, font=title_font, fill=(255,255,255))

    # Bullets
    text_x = x0 + 24
    text_y = y0 + 84
    max_w = w - 40
    for b in bullets:
        lines = text_wrap(d, "• " + b, body_font, max_w - 10)
        for ln in lines:
            d.text((text_x, text_y), ln, font=body_font, fill=(255,255,255))
            text_y += body_font.size + 6

def draw_header(base, text, fonts):
    d = ImageDraw.Draw(base)
    w, h = base.size
    title_font = fonts["h1"]
    # Decorative bar
    bar_w = int(w * 0.22)
    d.rectangle([MARGIN, MARGIN-12, MARGIN+bar_w, MARGIN-8], fill=(37,99,235))
    d.text((MARGIN, MARGIN+4), text, font=title_font, fill=(17,24,39))  # near-black

def generate(path=OUTPUT):
    W, H = SIZE
    base = Image.new("RGBA", (W, H), (245, 247, 250, 255))  # soft gray

    # Fonts
    fonts = {
        "h1": load_font(44, bold=True),
        "title": load_font(22, bold=True),
        "body": load_font(19, bold=False),
    }

    # Header
    draw_header(base, TITLE, fonts)

    # Layout: 2 rows x 4 columns
    grid_cols = 4
    grid_rows = 2
    usable_w = W - 2*MARGIN
    usable_h = H - (MARGIN + 60) - MARGIN  # top header area = ~60px
    cell_w = (usable_w - GAP*(grid_cols-1)) // grid_cols
    cell_h = (usable_h - GAP*(grid_rows-1)) // grid_rows

    top_y = MARGIN + 60

    idx = 0
    for r in range(grid_rows):
        for c in range(grid_cols):
            if idx >= len(CARDS): break
            x0 = MARGIN + c*(cell_w + GAP)
            y0 = top_y + r*(cell_h + GAP)
            x1 = x0 + cell_w
            y1 = y0 + cell_h
            card = CARDS[idx]
            draw_card(base, (x0, y0, x1, y1), card["title"], card["bullets"], card["grad"], card["icon"], fonts)
            idx += 1

    out = Path(path)
    base.convert("RGB").save(out, "PNG")
    return str(out)

if __name__ == "__main__":
    p = generate(OUTPUT)
    print("Saved:", p)
