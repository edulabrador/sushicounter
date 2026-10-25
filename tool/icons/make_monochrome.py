"""Builds the Android 13 themed-icon layer from the adaptive foreground.

Android tints this layer with the user's colors and only reads its alpha,
so the nigiri becomes a white silhouette with the nori band and the face cut
out, which keeps it recognisable in a single color.
"""
from PIL import Image

NORI = (0x24, 0x35, 0x28)
FACE = [(0x3A, 0x2A, 0x22), (0x7A, 0x3A, 0x2E)]


def close(rgb, target, tolerance=40):
    return all(abs(a - b) <= tolerance for a, b in zip(rgb, target))


src = Image.open('assets/icon/app_icon_foreground.png').convert('RGBA')
out = Image.new('RGBA', src.size, (0, 0, 0, 0))
pixels, result = src.load(), out.load()
for y in range(src.height):
    for x in range(src.width):
        r, g, b, a = pixels[x, y]
        if a < 128 or close((r, g, b), NORI) or any(close((r, g, b), f) for f in FACE):
            continue
        result[x, y] = (255, 255, 255, 255)
out.save('assets/icon/app_icon_monochrome.png')
