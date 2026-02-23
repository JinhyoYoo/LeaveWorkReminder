#!/usr/bin/env python3
"""퇴근 알리미 앱 아이콘 - SVG 버스 아이콘 중앙 정렬"""
from PIL import Image, ImageDraw
import os, subprocess, tempfile

SIZE = 1024
BG_PAD = 100
ICON_PAD = 220

# 1. 배경 생성
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)
bg = (55, 71, 133)
draw.rounded_rectangle(
    [BG_PAD, BG_PAD, SIZE - BG_PAD, SIZE - BG_PAD],
    radius=190, fill=bg
)

# 2. SVG → 흰색으로 변경
svg_path = os.path.expanduser("~/Downloads/bus-20.svg")
with open(svg_path, 'r') as f:
    svg = f.read()
svg = svg.replace('fill=""', 'fill="white"')
svg = svg.replace('fill: currentColor', 'fill: white')

tmp_svg = tempfile.NamedTemporaryFile(suffix='.svg', delete=False, mode='w')
tmp_svg.write(svg)
tmp_svg.close()

# 3. rsvg-convert로 PNG 렌더링
icon_size = SIZE - (ICON_PAD * 2)
tmp_png = tempfile.NamedTemporaryFile(suffix='.png', delete=False)
tmp_png.close()

subprocess.run([
    'rsvg-convert',
    '-w', str(icon_size),
    '-h', str(icon_size),
    '-o', tmp_png.name,
    tmp_svg.name
], check=True)

bus_icon = Image.open(tmp_png.name).convert('RGBA')

# 4. 중앙 정렬하여 합성
img.paste(bus_icon, (ICON_PAD, ICON_PAD), bus_icon)

# 5. iconset 생성
iconset_dir = os.path.expanduser("~/LeaveWorkReminder/AppIcon.iconset")
os.makedirs(iconset_dir, exist_ok=True)

for name, sz in [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]:
    img.resize((sz, sz), Image.LANCZOS).save(os.path.join(iconset_dir, name))

img.save(os.path.expanduser("~/LeaveWorkReminder/icon_preview.png"))

os.unlink(tmp_svg.name)
os.unlink(tmp_png.name)
print("완료")
