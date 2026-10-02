"""Original 5x7 lettering for the Faroleiro HUD; writes a BMFont and PNG atlas."""
from pathlib import Path
import struct
import unicodedata
import zlib

OUT = Path(__file__).resolve().parents[1] / "assets" / "ui"
GLYPHS = {
    "A": "0E 11 11 1F 11 11 11", "B": "1E 11 11 1E 11 11 1E",
    "C": "0F 10 10 10 10 10 0F", "D": "1E 11 11 11 11 11 1E",
    "E": "1F 10 10 1E 10 10 1F", "F": "1F 10 10 1E 10 10 10",
    "G": "0F 10 10 17 11 11 0F", "H": "11 11 11 1F 11 11 11",
    "I": "0E 04 04 04 04 04 0E", "J": "07 02 02 02 12 12 0C",
    "K": "11 12 14 18 14 12 11", "L": "10 10 10 10 10 10 1F",
    "M": "11 1B 15 15 11 11 11", "N": "11 19 15 13 11 11 11",
    "O": "0E 11 11 11 11 11 0E", "P": "1E 11 11 1E 10 10 10",
    "Q": "0E 11 11 11 15 12 0D", "R": "1E 11 11 1E 14 12 11",
    "S": "0F 10 10 0E 01 01 1E", "T": "1F 04 04 04 04 04 04",
    "U": "11 11 11 11 11 11 0E", "V": "11 11 11 11 11 0A 04",
    "W": "11 11 11 15 15 1B 11", "X": "11 11 0A 04 0A 11 11",
    "Y": "11 11 0A 04 04 04 04", "Z": "1F 01 02 04 08 10 1F",
    "a": "00 00 0E 01 0F 11 0F", "b": "10 10 1E 11 11 11 1E",
    "c": "00 00 0F 10 10 10 0F", "d": "01 01 0F 11 11 11 0F",
    "e": "00 00 0E 11 1F 10 0F", "f": "06 08 08 1E 08 08 08",
    "g": "00 0F 11 11 0F 01 0E", "h": "10 10 1E 11 11 11 11",
    "i": "04 00 0C 04 04 04 0E", "j": "02 00 06 02 02 12 0C",
    "k": "10 10 12 14 18 14 12", "l": "0C 04 04 04 04 04 0E",
    "m": "00 00 1A 15 15 15 15", "n": "00 00 1E 11 11 11 11",
    "o": "00 00 0E 11 11 11 0E", "p": "00 1E 11 11 1E 10 10",
    "q": "00 0F 11 11 0F 01 01", "r": "00 00 16 19 10 10 10",
    "s": "00 00 0F 10 0E 01 1E", "t": "08 08 1E 08 08 08 06",
    "u": "00 00 11 11 11 11 0F", "v": "00 00 11 11 11 0A 04",
    "w": "00 00 11 11 15 15 0A", "x": "00 00 11 0A 04 0A 11",
    "y": "00 11 11 11 0F 01 0E", "z": "00 00 1F 02 04 08 1F",
    "0": "0E 11 13 15 19 11 0E", "1": "04 0C 04 04 04 04 0E",
    "2": "0E 11 01 02 04 08 1F", "3": "1E 01 01 0E 01 01 1E",
    "4": "02 06 0A 12 1F 02 02", "5": "1F 10 10 1E 01 01 1E",
    "6": "0E 10 10 1E 11 11 0E", "7": "1F 01 02 04 08 08 08",
    "8": "0E 11 11 0E 11 11 0E", "9": "0E 11 11 0F 01 01 0E",
    ":": "00 04 04 00 04 04 00", ".": "00 00 00 00 00 0C 0C",
    ",": "00 00 00 00 04 04 08", "/": "01 01 02 04 08 10 10",
    "!": "04 04 04 04 04 00 04", "?": "0E 11 01 02 04 00 04",
    "-": "00 00 00 1F 00 00 00", "+": "00 04 04 1F 04 04 00",
    "(": "02 04 08 08 08 04 02", ")": "08 04 02 02 02 04 08",
    "·": "00 00 00 04 00 00 00", "…": "00 00 00 00 00 00 15",
    "'": "04 04 08 00 00 00 00", " ": "00 00 00 00 00 00 00",
}
ACCENTS = {"\u0301": [2, 4], "\u0300": [8, 4], "\u0302": [4, 10],
           "\u0303": [10, 20], "\u0308": [10, 0], "\u0327": [4, 8]}


def chunk(kind, data):
    return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    chars = sorted(set(GLYPHS) | set("áàâãéêíóôõúüçÁÀÂÃÉÊÍÓÔÕÚÜÇ"))
    width, height = 128, 128
    pixels = bytearray(width * height * 4)
    lines = ['info face="Faroleiro" size=8 bold=0 italic=0 unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1',
             'common lineHeight=12 base=10 scaleW=128 scaleH=128 pages=1 packed=0',
             'page id=0 file="faroleiro-font.png"', f'chars count={len(chars)}']
    for index, char in enumerate(chars):
        decomposition = unicodedata.normalize("NFD", char)
        base = decomposition[0] if len(decomposition) > 1 else char
        rows = [0, 0, 0] + [int(row, 16) for row in GLYPHS[base].split()] + [0, 0]
        if len(decomposition) > 1:
            accent = decomposition[1]
            rows[10:12] = ACCENTS[accent] if accent == "\u0327" else [0, 0]
            if accent != "\u0327":
                rows[:2] = ACCENTS[accent]
        x, y = index % 16 * 8, index // 16 * 12
        for dy, row in enumerate(rows):
            for dx in range(5):
                if row & (1 << (4 - dx)):
                    at = ((y + dy) * width + x + dx) * 4
                    pixels[at:at + 4] = b'\xff\xff\xff\xff'
        lines.append(f'char id={ord(char)} x={x} y={y} width=5 height=12 xoffset=0 yoffset=0 xadvance={4 if char == " " else 6} page=0 chnl=15')
    raw = b''.join(b'\x00' + pixels[y * width * 4:(y + 1) * width * 4] for y in range(height))
    provenance = b'Description\x00Original Faroleiro HUD lettering: authored 5x7 glyphs, Portuguese accents, transparent white bitmap; tools/generate_hud_font.py'
    png = b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0))
    png += chunk(b'tEXt', provenance) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b'')
    (OUT / 'faroleiro-font.png').write_bytes(png)
    (OUT / 'faroleiro.fnt').write_text('\n'.join(lines) + '\n')


if __name__ == '__main__':
    main()
