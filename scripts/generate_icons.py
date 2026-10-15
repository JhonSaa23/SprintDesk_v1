#!/usr/bin/env python3
"""
SprintDesk Icon & Branding Generator
Generates all application icons across macOS (.icns), Windows (.ico),
Linux (PNGs), Android (mipmaps), iOS (AppIcon), and Flutter In-App assets.
"""
import os
import shutil
import subprocess
import base64
from io import BytesIO
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_IMG_PATH = os.path.join(ROOT, 'res/sprintdesk_source_logo.png')

if not os.path.exists(SRC_IMG_PATH):
    raise FileNotFoundError(f"Source image not found: {SRC_IMG_PATH}")

print("Loading master source image:", SRC_IMG_PATH)
raw_img = Image.open(SRC_IMG_PATH).convert('RGBA')

# 1. Master Square Icon 1024x1024
CANVAS_SIZE = 1024
master_icon = Image.new('RGBA', (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
target_w = 880
target_h = int(raw_img.height * (target_w / raw_img.width))
resized_emblem = raw_img.resize((target_w, target_h), Image.Resampling.LANCZOS)
x_pos = (CANVAS_SIZE - target_w) // 2
y_pos = (CANVAS_SIZE - target_h) // 2
master_icon.paste(resized_emblem, (x_pos, y_pos), resized_emblem)

# 2. macOS AppIcon.icns
print("Generating macOS AppIcon.icns...")
iconset_dir = '/tmp/SprintDesk.iconset'
if os.path.exists(iconset_dir):
    shutil.rmtree(iconset_dir)
os.makedirs(iconset_dir, exist_ok=True)

mac_sizes = [
    ('icon_16x16.png', 16),
    ('icon_16x16@2x.png', 32),
    ('icon_32x32.png', 32),
    ('icon_32x32@2x.png', 64),
    ('icon_128x128.png', 128),
    ('icon_128x128@2x.png', 256),
    ('icon_256x256.png', 256),
    ('icon_256x256@2x.png', 512),
    ('icon_512x512.png', 512),
    ('icon_512x512@2x.png', 1024),
]
for fname, sz in mac_sizes:
    master_icon.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(iconset_dir, fname))

mac_icns_target = os.path.join(ROOT, 'flutter/macos/Runner/AppIcon.icns')
subprocess.run(['iconutil', '-c', 'icns', iconset_dir, '-o', mac_icns_target], check=True)

# 3. Windows .ico files
print("Generating Windows .ico files...")
win_sizes = [(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
for target in [
    os.path.join(ROOT, 'flutter/windows/runner/resources/app_icon.ico'),
    os.path.join(ROOT, 'res/icon.ico'),
    os.path.join(ROOT, 'res/tray-icon.ico'),
]:
    master_icon.save(target, format='ICO', sizes=win_sizes)

# 4. Linux and generic res files
print("Generating Linux & desktop assets in res/...")
res_files = [
    ('res/icon.png', 512),
    ('res/mac-icon.png', 256),
    ('res/128x128.png', 128),
    ('res/128x128@2x.png', 256),
    ('res/64x64.png', 64),
    ('res/32x32.png', 32),
    ('res/mac-tray-dark-x2.png', 44),
    ('res/mac-tray-light-x2.png', 44),
]
for rel_path, sz in res_files:
    target = os.path.join(ROOT, rel_path)
    master_icon.resize((sz, sz), Image.Resampling.LANCZOS).save(target)

# 5. Flutter assets
print("Generating Flutter assets...")
flutter_icon_png = os.path.join(ROOT, 'flutter/assets/icon.png')
master_icon.resize((512, 512), Image.Resampling.LANCZOS).save(flutter_icon_png)

png_buffer = BytesIO()
master_icon.resize((512, 512), Image.Resampling.LANCZOS).save(png_buffer, format='PNG')
b64_png = base64.b64encode(png_buffer.getvalue()).decode('utf-8')
svg_content = f'''<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 512 512" width="512" height="512">
  <image width="512" height="512" xlink:href="data:image/png;base64,{b64_png}"/>
</svg>'''
with open(os.path.join(ROOT, 'flutter/assets/icon.svg'), 'w') as f:
    f.write(svg_content)
with open(os.path.join(ROOT, 'res/logo.svg'), 'w') as f:
    f.write(svg_content)

# 6. Horizontal Brand Logo for Flutter
logo_img = Image.new('RGBA', (640, 140), (0, 0, 0, 0))
emb_h = 120
emb_w = int(raw_img.width * (emb_h / raw_img.height))
emb_resized = raw_img.resize((emb_w, emb_h), Image.Resampling.LANCZOS)
logo_img.paste(emb_resized, (10, 10), emb_resized)

draw = ImageDraw.Draw(logo_img)
font_path = '/System/Library/Fonts/Helvetica.ttc'
try:
    font = ImageFont.truetype(font_path, 68)
except:
    font = ImageFont.load_default()

draw.text((emb_w + 28, 30), "Sprint", fill=(255, 255, 255, 255), font=font)
bbox = font.getbbox("Sprint") if hasattr(font, 'getbbox') else (0, 0, 220, 70)
sprint_w = bbox[2] - bbox[0]
draw.text((emb_w + 32 + sprint_w, 30), "Desk", fill=(56, 189, 248, 255), font=font)

for target in [
    os.path.join(ROOT, 'flutter/assets/logo.png'),
    os.path.join(ROOT, 'flutter/assets/logo_dark.png'),
    os.path.join(ROOT, 'flutter/assets/logo_light.png'),
]:
    logo_img.save(target)

# 7. Android Mipmaps
print("Generating Android mipmaps...")
android_res = os.path.join(ROOT, 'flutter/android/app/src/main/res')
android_configs = [
    ('mipmap-mdpi', 48, 24, 108),
    ('mipmap-hdpi', 72, 36, 162),
    ('mipmap-xhdpi', 96, 48, 216),
    ('mipmap-xxhdpi', 144, 72, 324),
    ('mipmap-xxxhdpi', 192, 96, 432),
]
for folder, sz, stat_sz, fg_sz in android_configs:
    d = os.path.join(android_res, folder)
    if os.path.exists(d):
        master_icon.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(d, 'ic_launcher.png'))
        master_icon.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(d, 'ic_launcher_round.png'))
        master_icon.resize((stat_sz, stat_sz), Image.Resampling.LANCZOS).save(os.path.join(d, 'ic_stat_logo.png'))
        master_icon.resize((fg_sz, fg_sz), Image.Resampling.LANCZOS).save(os.path.join(d, 'ic_launcher_foreground.png'))

# 8. iOS AppIcon
print("Generating iOS icons...")
ios_dir = os.path.join(ROOT, 'flutter/ios/Runner/Assets.xcassets/AppIcon.appiconset')
ios_sizes = [
    ('Icon-App-20x20@1x.png', 20),
    ('Icon-App-20x20@2x.png', 40),
    ('Icon-App-20x20@3x.png', 60),
    ('Icon-App-29x29@1x.png', 29),
    ('Icon-App-29x29@2x.png', 58),
    ('Icon-App-29x29@3x.png', 87),
    ('Icon-App-40x40@1x.png', 40),
    ('Icon-App-40x40@2x.png', 80),
    ('Icon-App-40x40@3x.png', 120),
    ('Icon-App-60x60@2x.png', 120),
    ('Icon-App-60x60@3x.png', 180),
    ('Icon-App-76x76@1x.png', 76),
    ('Icon-App-76x76@2x.png', 152),
    ('Icon-App-83.5x83.5@2x.png', 167),
    ('Icon-App-1024x1024@1x.png', 1024),
]
if os.path.exists(ios_dir):
    for fname, sz in ios_sizes:
        master_icon.resize((sz, sz), Image.Resampling.LANCZOS).save(os.path.join(ios_dir, fname))

print("All branding and icon assets generated successfully!")
