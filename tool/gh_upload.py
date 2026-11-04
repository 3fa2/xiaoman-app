# -*- coding: utf-8 -*-
"""GitHub 全自动上传（2026-11-04）：device flow（自动轮询）→ token 内存流转 →
force push main → 清远端旧 tags → 推 v5.8.3 tag → 创建/更新 Release 挂 APK。
用法：python -I tool/gh_upload.py（项目根运行）。token 绝不打印/落盘。"""
import json
import os
import subprocess
import sys
import time
import urllib.parse
import urllib.request

PROXY = 'http://127.0.0.1:65532'
CLIENT_ID = '178c6fc778ccc68e1d6a'  # GitHub CLI 公开 client_id
OWNER, REPO, TAG = '3fa2', 'xiaoman-app', 'v5.8.3'
APK = r'E:\DeepSeek\apk\小满-v5.8.3.apk'

env = dict(os.environ)
env['HTTPS_PROXY'] = PROXY
env['HTTP_PROXY'] = PROXY
TOKEN = {'v': None}


def post(url, form):
    # urllib 的 TLS 在本机经代理会被 RST，curl 稳定——全部走 curl 子进程
    form_parts = []
    for k, v in form.items():
        form_parts += ['-d', '{}={}'.format(k, v)]
    p = subprocess.run(
        ['curl', '-s', '-x', PROXY, '--max-time', '60', '-X', 'POST',
         '-H', 'Accept: application/json'] + form_parts + [url],
        capture_output=True)
    return json.loads(p.stdout.decode('utf-8'))


def api(method, path, payload=None):
    req = urllib.request.Request(
        'https://api.github.com' + path, method=method,
        data=json.dumps(payload).encode() if payload else None,
        headers={'Authorization': 'Bearer ' + TOKEN['v'],
                 'Accept': 'application/vnd.github+json',
                 'User-Agent': 'xiaoman-upload'})
    opener = urllib.request.build_opener(
        urllib.request.ProxyHandler({'https': PROXY, 'http': PROXY}))
    try:
        with opener.open(req, timeout=60) as r:
            return r.status, json.loads(r.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read().decode('utf-8'))


def git_push(*args):
    turl = 'https://x-access-token:{}@github.com/{}/{}/{}.git'.format(
        urllib.parse.quote(TOKEN['v']), OWNER, REPO, REPO)
    p = subprocess.run(['git', 'push', turl, *args],
                       capture_output=True, env=env)
    return p.returncode, p.stderr.decode('utf-8', 'replace')


def main():
    # 1. 申请设备码
    d = post('https://github.com/login/device/code',
             {'client_id': CLIENT_ID, 'scope': 'repo'})
    print('== 请在浏览器打开:', d['verification_uri'])
    print('== 输入一次性代码:', d['user_code'])
    print('== 等待授权中（最长 15 分钟，授权后自动继续）...')
    sys.stdout.flush()

    # 2. 轮询换 token
    interval = d.get('interval', 5)
    deadline = time.time() + d.get('expires_in', 899)
    token = None
    while time.time() < deadline:
        time.sleep(interval)
        r = post('https://github.com/login/oauth/access_token',
                 {'client_id': CLIENT_ID, 'device_code': d['device_code'],
                  'grant_type': 'urn:ietf:params:oauth:grant-type:device_code'})
        if 'access_token' in r:
            token = r['access_token']
            break
        err = r.get('error')
        if err == 'authorization_pending':
            continue
        if err == 'slow_down':
            interval += 5
            continue
        print('授权失败:', err)
        sys.exit(3)
    if not token:
        print('超时未授权'); sys.exit(3)
    TOKEN['v'] = token
    print('[1/4] 授权成功，token 已就绪（隐藏）')

    # 3. force push main + 清旧 tags + 推 v5.8.3
    rc, err = git_push('--force', 'main')
    print('[2/4] force push main:', 'OK' if rc == 0 else err[-300:])
    if rc != 0:
        sys.exit(4)
    for t in ['v4.8.0', 'v5.0.3', 'v5.0.4', 'v5.4.2', 'v5.4.3',
              'v5.5.0', 'v5.5.1', 'v5.8.3']:
        rc, err = git_push('--delete', t)
        if rc == 0:
            print('  del tag', t, ': ok')
    rc, err = git_push(TAG)
    print('  push tag v5.8.3:', 'OK' if rc == 0 else err[-150:])

    # 4. Release（存在则更新说明）
    st, rel = api('POST', '/repos/{}/{}/releases'.format(OWNER, REPO), {
        'tag_name': TAG,
        'name': '小满 v5.8.3',
        'body': (
            '## 小满 v5.8.3+50\n\n'
            '本地优先的日记 · 备忘 · 待办 · 日程 Android 应用'
            '（数据只在你的手机上）。\n\n'
            '### 近期要点\n'
            '- v5.8.3：记录统计页视觉修正（四卡等高居中、热力图深色可辨）\n'
            '- v5.8.2：图片打开/关闭卡顿优化（按屏幕分辨率解码 + 预解码并行）\n'
            '- v5.8.1：那年今天 · 写作灵感 · Material You · 应用内更新记录\n'
            '- v5.8.0：完整备份（含媒体）· 记录统计 · 日记分享卡片 · '
            '心情打卡小组件\n\n'
            '### 安装\n下载下方 APK 直接安装（Android 8+）。签名 CN=Trinity，'
            '覆盖安装数据不丢。\n\n完整变更见仓库 CHANGELOG.md。'
        ),
        'draft': False, 'prerelease': False,
    })
    if st not in (200, 201):
        # 已存在则改用 PATCH
        st, rel = api('GET', '/repos/{}/{}/releases/tags/{}'.format(
            OWNER, REPO, TAG), None)
        if st == 200:
            st, rel = api('PATCH', '/repos/{}/{}/releases/{}'.format(
                OWNER, REPO, rel['id']), {'name': '小满 v5.8.3'})
    print('[3/4] release:', rel.get('html_url', 'FAIL ' + str(st)))
    asset_names = {a['name'] for a in rel.get('assets', [])}

    # 5. APK（缺或名不对则重传）
    want = 'xiaoman-v5.8.3.apk'
    if want not in asset_names:
        upload_url = rel['upload_url'].split('{')[0]
        with open(APK, 'rb') as f:
            apk = f.read()
        req = urllib.request.Request(
            upload_url + '?name=' + want, method='POST', data=apk,
            headers={'Authorization': 'Bearer ' + TOKEN['v'],
                     'Content-Type': 'application/vnd.android.package-archive',
                     'Content-Length': str(len(apk)),
                     'User-Agent': 'xiaoman-upload'})
        opener = urllib.request.build_opener(
            urllib.request.ProxyHandler({'https': PROXY, 'http': PROXY}))
        with opener.open(req, timeout=600) as r:
            out = json.loads(r.read().decode('utf-8'))
        print('[4/4] APK 上传:', out.get('browser_download_url', ''),
              out.get('size'), 'bytes')
        # 清理可能的旧残缺 asset（如 -v5.8.3.apk）
        for a in rel.get('assets', []):
            if a['name'] != want and a['name'].endswith('.apk'):
                api('DELETE', '/repos/{}/{}/releases/assets/{}'.format(
                    OWNER, REPO, a['id']))
                print('  删除旧 asset:', a['name'])
    else:
        print('[4/4] APK 已存在:', want)

    st, ref = api('GET', '/repos/{}/{}/git/refs/heads/main'.format(
        OWNER, REPO), None)
    print('[done] remote main =',
          ref.get('object', {}).get('sha', '?')[:10])


if __name__ == '__main__':
    main()
