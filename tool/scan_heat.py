# -*- coding: utf-8 -*-
"""扫描热力图区域全部非灰点，输出坐标+颜色。"""
import struct
import zlib

path = r'E:\DeepSeek\apk\mumu-shots\14_stats.png'
raw = open(path, 'rb').read()
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

# 扫描热力图区域：y 690-870, x 70-1010——找饱和度高的彩点
import colorsys
found = []
y = 695
while y < 870:
    x = 70
    while x < 1010:
        r, g, b = px(x, y)
        mx, mn = max(r, g, b), min(r, g, b)
        # 彩色 = 通道差大 且 亮度高（非灰）
        if mx - mn > 30 and mx > 90:
            found.append((x, y, (r, g, b)))
            x += 14  # 跳过同点其余像素
        x += 1
    y += 1

for x, y, c in found:
    h = colorsys.rgb_to_hls(c[0] / 255, c[1] / 255, c[2] / 255)
    print('({},{}) {} hue={:.0f} l={:.2f}'.format(x, y, c, h[0] * 360, h[1]))
print('total:', len(found))
