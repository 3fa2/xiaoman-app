# -*- coding: utf-8 -*-
"""取 04_stats_page.png 热力图两个彩点的像素色，与 MoodPalette 预期对比。"""
import struct
import zlib

path = r'E:\DeepSeek\apk\mumu-shots\04_stats_page.png'
raw = open(path, 'rb').read()

# 最小 PNG 解码（真彩 8-bit）
pos = 8
width = height = 0
idat = b''
while pos < len(raw):
    length = struct.unpack('>I', raw[pos:pos + 4])[0]
    ctype = raw[pos + 4:pos + 8]
    data = raw[pos + 8:pos + 8 + length]
    if ctype == b'IHDR':
        width, height = struct.unpack('>II', data[:8])
        bit_depth, color_type = data[8], data[9]
        print('size:', width, 'x', height, 'depth:', bit_depth,
              'color:', color_type)
    elif ctype == b'IDAT':
        idat += data
    elif ctype == b'IEND':
        break
    pos += 12 + length

raw_data = zlib.decompress(idat)
bpp = 4 if color_type == 6 else 3
stride = width * bpp + 1
out = bytearray()
prev = bytearray(width * bpp)
for y in range(height):
    row = raw_data[y * stride:(y + 1) * stride]
    ft = row[0]
    line = bytearray(row[1:])
    for x in range(len(line)):
        a = line[x - bpp] if x >= bpp else 0
        b = prev[x]
        c = prev[x - bpp] if x >= bpp else 0
        if ft == 1:
            line[x] = (line[x] + a) & 0xFF
        elif ft == 2:
            line[x] = (line[x] + b) & 0xFF
        elif ft == 3:
            line[x] = (line[x] + (a + b) // 2) & 0xFF
        elif ft == 4:
            pa, pb, pc = abs(b - c), abs(a - c), abs(a + b - 2 * c)
            pr = a if pa <= pb and pa <= pc else (b if pb <= pc else c)
            line[x] = (line[x] + pr) & 0xFF
    out += line
    prev = line

def px(x, y):
    o = (y * width + x) * bpp
    return tuple(out[o:o + 3])

# 热力图两个彩点坐标（截图目测）：蓝点 ~(628,710)，黄点 ~(628,738)
for name, (x, y) in [('blue-dot', (628, 710)), ('yellow-dot', (628, 738)),
                     ('today-ring', (730, 791)), ('empty-grid', (300, 710)),
                     ('card-bg', (540, 690))]:
    print(name, (x, y), '->', px(x, y))

# MoodPalette 预期（dark: l=0.56, s=0.40）
import colorsys
for name, hue in [('开心', 50), ('期待', 130), ('平静', 190), ('感动', 330),
                  ('疲惫', 260), ('难过', 215), ('焦虑', 25), ('生气', 0)]:
    r, g, b = [int(v * 255) for v in colorsys.hls_to_rgb(
        hue / 360, 0.56, 0.40)]
    print('expected', name, hue, '-> #%02X%02X%02X' % (r, g, b), (r, g, b))
