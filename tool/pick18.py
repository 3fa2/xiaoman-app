# -*- coding: utf-8 -*-
"""取 18_stats_fixed.png 热力图点色。"""
import struct
import zlib

path = r'E:\DeepSeek\apk\mumu-shots\18_stats_fixed.png'
raw = open(path, 'rb').read()
pos = 8
width = height = 0
idat = b''
color_type = 6
while pos < len(raw):
    length = struct.unpack('>I', raw[pos:pos + 4])[0]
    ctype = raw[pos + 4:pos + 8]
    data = raw[pos + 8:pos + 8 + length]
    if ctype == b'IHDR':
        width, height = struct.unpack('>II', data[:8])
        color_type = data[9]
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


print('size:', width, 'x', height, 'bpp:', bpp)
for name, (x, y) in [('dot1-blue?', (628, 710)), ('dot2-yellow?', (628, 737)),
                     ('today', (730, 790)), ('empty-grid', (300, 710))]:
    print(name, (x, y), '->', px(x, y))
