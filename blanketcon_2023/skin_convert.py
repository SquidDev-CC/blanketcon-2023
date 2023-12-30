import io
import os.path
import argparse

from PIL import Image

neural = Image.open(os.path.join(os.path.dirname(__file__), "interface.png"))


def format_texture(out: io.StringIO, texture: Image.Image):
    width, height = texture.size
    for y in range(height):
        out.write('"')
        for x in range(width):
            out.write("%x" % texture.getpixel((x, y)))
        out.write('",')


def convert_skin(texture: Image.Image) -> str:
    alpha = texture.convert("RGBA").split()[-1]
    sprite = Image.new("RGB", texture.size, (240, 240, 240))
    sprite.paste(texture, mask=alpha)

    neural_sprite = sprite.copy()
    neural_sprite.paste(neural, (14, 6))
    neural_texture = neural_sprite.quantize(
        colors=14,
        method=Image.Quantize.MAXCOVERAGE,
        kmeans=14,
        dither=Image.Dither.NONE,
    )

    texture = sprite.quantize(
        colors=14, dither=Image.Dither.NONE, palette=neural_texture
    )

    out = io.StringIO()
    out.write("{palette={")

    palette = neural_texture.getpalette()
    if palette is None:
        raise ValueError("Palette cannot be None")
    for p in range(14):
        out.write(
            f"{palette[p * 3] << 16 | palette[p * 3 + 1] << 8 | palette[p * 3 + 2]},"
        )
    out.write("},normal={")
    format_texture(out, texture)
    out.write("},neural={")
    format_texture(out, neural_texture)
    out.write("}}")

    return out.getvalue()


if __name__ == "__main__":
    spec = argparse.ArgumentParser(description="Convert a skin to a CC file")
    spec.add_argument("path", help="The path to the skin", metavar="PATH")

    args = spec.parse_args()

    print(convert_skin(Image.open(args.path)))
