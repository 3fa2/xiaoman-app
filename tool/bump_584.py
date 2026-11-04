# -*- coding: utf-8 -*-
"""版本 bump 5.8.4+51（修复 PowerShell 写坏的 BOM/编码）：pubspec 恢复自 git
再精确替换版本；local.properties / version.dart 去 BOM。"""
import io

# 1. pubspec（已从 git 恢复为 5.8.3+50 正确内容）→ 精确 bump
c = io.open('pubspec.yaml', encoding='utf-8').read()
assert 'version: 5.8.3+50' in c, 'pubspec not at 5.8.3+50'
c = c.replace('version: 5.8.3+50', 'version: 5.8.4+51')
with io.open('pubspec.yaml', 'w', encoding='utf-8', newline='') as f:
    f.write(c)

# 2. 去 BOM（如有）
for p in ('android/local.properties', 'lib/design/version.dart'):
    raw = open(p, 'rb').read()
    if raw.startswith(b'\xef\xbb\xbf'):
        open(p, 'wb').write(raw[3:])
        print('BOM removed:', p)

# 3. version.dart 内容核对/修正
vd = io.open('lib/design/version.dart', encoding='utf-8').read()
if "appVersionName = '5.8.4'" not in vd:
    vd = vd.replace("appVersionName = '5.8.3'", "appVersionName = '5.8.4'")
    vd = vd.replace('appVersionCode = 50', 'appVersionCode = 51')
    with io.open('lib/design/version.dart', 'w', encoding='utf-8',
                 newline='') as f:
        f.write(vd)
    print('version.dart rewritten')

# 4. local.properties 内容核对（BOM 去除后应有效；字段不对则重写）
lp = io.open('android/local.properties', encoding='utf-8').read()
if 'flutter.versionName=5.8.4' not in lp:
    with io.open('android/local.properties', 'w', encoding='utf-8',
                 newline='') as f:
        f.write('sdk.dir=E:\\\\android-sdk\n'
                'flutter.sdk=E:\\\\flutter_sdk\\flutter\n'
                'flutter.buildMode=release\n'
                'flutter.versionName=5.8.4\n'
                'flutter.versionCode=51\n')
    print('local.properties rewritten')

print('verify pubspec:', [l.strip() for l in
                          io.open('pubspec.yaml', encoding='utf-8')
                          if l.startswith('version')])
print('done')
