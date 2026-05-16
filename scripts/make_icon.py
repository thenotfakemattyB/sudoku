"""
Generate the app icon for the Sudoku iOS app.

Output: a 1024x1024 PNG suitable for Xcode 15+'s "Single Size" App Icon
asset. Xcode auto-generates every required smaller size from this one PNG.

Design: soft blue gradient background, white inset card with a 3x3 grid
(visible at small sizes), a few sample digits in dark navy.
"""
from PIL import Image, ImageDraw, ImageFont
import os

SIZE = 1024
OUTPUT = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "Sudoku", "Assets.xcassets", "AppIcon.appiconset", "AppIcon.png"
)


def gradient_bg(im: Image.Image) -> None:
    """Diagonal blue gradient — light top-left to deeper bottom-right."""
    top = (90, 160, 232)      # #5AA0E8 — light sky blue
    bot = (45, 112, 192)      # #2D70C0 — deeper blue
    px = im.load()
    for y in range(SIZE):
        for x in range(SIZE):
            t = (x + y) / (2 * SIZE)
            r = int(top[0] * (1 - t) + bot[0] * t)
            g = int(top[1] * (1 - t) + bot[1] * t)
            b = int(top[2] * (1 - t) + bot[2] * t)
            px[x, y] = (r, g, b, 255)


def rounded_rect(draw, xy, radius, fill):
    """Pillow has rounded_rectangle since 8.2 — use it directly."""
    draw.rounded_rectangle(xy, radius=radius, fill=fill)


def best_font(size: int) -> ImageFont.FreeTypeFont:
    """Pick a clean bold rounded font available on the system."""
    candidates = [
        "C:/Windows/Fonts/seguisb.ttf",   # Segoe UI Semibold
        "C:/Windows/Fonts/segoeui.ttf",   # Segoe UI
        "C:/Windows/Fonts/arialbd.ttf",   # Arial Bold
        "C:/Windows/Fonts/arial.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def draw_grid_and_digits(draw: ImageDraw.ImageDraw) -> None:
    # The white card occupies the central ~76% of the canvas.
    margin = int(SIZE * 0.12)
    card_box = (margin, margin, SIZE - margin, SIZE - margin)
    rounded_rect(draw, card_box, radius=int(SIZE * 0.10), fill=(255, 255, 255, 255))

    # 3x3 grid lines (interior only — the card edge is the outer border).
    line_color = (35, 60, 110, 255)   # dark navy
    line_width = int(SIZE * 0.020)
    card_w = card_box[2] - card_box[0]
    step = card_w / 3
    for i in (1, 2):
        # vertical
        x = card_box[0] + step * i
        draw.line([(x, card_box[1]), (x, card_box[3])],
                  fill=line_color, width=line_width)
        # horizontal
        y = card_box[1] + step * i
        draw.line([(card_box[0], y), (card_box[2], y)],
                  fill=line_color, width=line_width)

    # A few sample digits — placed asymmetrically for a "real puzzle" feel.
    # Format: (row, col, char). Rows/cols 0-2.
    digits = [
        (0, 0, "5"),
        (0, 2, "3"),
        (1, 1, "7"),
        (2, 0, "9"),
        (2, 2, "1"),
    ]
    font = best_font(int(step * 0.62))
    for row, col, ch in digits:
        cx = card_box[0] + step * (col + 0.5)
        cy = card_box[1] + step * (row + 0.5)
        bbox = draw.textbbox((0, 0), ch, font=font)
        w = bbox[2] - bbox[0]
        h = bbox[3] - bbox[1]
        # textbbox includes a top offset — subtract it to truly center.
        draw.text((cx - w / 2 - bbox[0], cy - h / 2 - bbox[1]),
                  ch, fill=line_color, font=font)


def main() -> None:
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 255))
    gradient_bg(im)
    draw = ImageDraw.Draw(im, "RGBA")
    draw_grid_and_digits(draw)
    # iOS app icons should be opaque (no alpha channel). Flatten to RGB.
    out = Image.new("RGB", (SIZE, SIZE), (0, 0, 0))
    out.paste(im, (0, 0), im)
    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    out.save(OUTPUT, "PNG", optimize=True)
    print(f"Wrote {OUTPUT} ({os.path.getsize(OUTPUT) / 1024:.1f} KB)")


if __name__ == "__main__":
    main()
