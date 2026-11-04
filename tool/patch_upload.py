# -*- coding: utf-8 -*-
"""gh_upload.py 的 post() 换成 curl 子进程（urllib TLS 经代理被 RST）。"""
import io

path = 'tool/gh_upload.py'
c = io.open(path, encoding='utf-8').read()
old = """def post(url, form):
    data = urllib.parse.urlencode(form).encode()
    req = urllib.request.Request(url, data=data, headers={
        'Accept': 'application/json', 'User-Agent': 'xiaoman-upload'})
    opener = urllib.request.build_opener(
        urllib.request.ProxyHandler({'https': PROXY, 'http': PROXY}))
    with opener.open(req, timeout=60) as r:
        return json.loads(r.read().decode('utf-8'))"""
new = """def post(url, form):
    # urllib 的 TLS 在本机经代理会被 RST，curl 稳定——全部走 curl 子进程
    form_parts = []
    for k, v in form.items():
        form_parts += ['-d', '{}={}'.format(k, v)]
    p = subprocess.run(
        ['curl', '-s', '-x', PROXY, '--max-time', '60', '-X', 'POST',
         '-H', 'Accept: application/json'] + form_parts + [url],
        capture_output=True)
    return json.loads(p.stdout.decode('utf-8'))"""
assert old in c, 'old post() not found'
with io.open(path, 'w', encoding='utf-8', newline='') as f:
    f.write(c.replace(old, new))
print('patched ok')
