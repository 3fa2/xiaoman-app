# -*- coding: utf-8 -*-
"""交付前 APK 校验：libapp.so 必须存在（防 AOT 任务静默跳过 → 启动 SIGSEGV），
版本号/签名可另走 aapt/apksigner。用法：python tool/verify_apk.py <apk路径>"""
import sys
import zipfile

# libapp.so 低于该值（KB）视为空壳，按缺失处理
MIN_LIBAPP_KB = 1024


def main():
    if len(sys.argv) < 2:
        print('用法: python tool/verify_apk.py <apk>')
        sys.exit(2)
    apk = sys.argv[1]
    try:
        z = zipfile.ZipFile(apk)
    except Exception as e:
        print('[FAIL] 打不开 APK：%s' % e)
        sys.exit(1)
    names = z.namelist()
    libapp = sorted(
        n for n in names if n.startswith('lib/') and n.endswith('/libapp.so')
    )
    libflutter = sorted(
        n for n in names if n.startswith('lib/') and n.endswith('/libflutter.so')
    )
    abis = sorted(n.split('/')[1] for n in libapp)
    ok = True
    if not libapp:
        print('[FAIL] libapp.so 缺失 —— Dart AOT 快照未打包，装上必闪退！')
        print('       处理：flutter clean 后重新 build；构建完必须重跑本脚本。')
        ok = False
    else:
        # abis 与 libapp 均已排序，zip 配对不会错位
        for abi, n in zip(abis, libapp):
            size_kb = z.getinfo(n).file_size // 1024
            if size_kb < MIN_LIBAPP_KB:
                print(
                    '[FAIL] libapp.so (%s) 只有 %dKB —— 疑似空壳，按缺失处理'
                    % (abi, size_kb)
                )
                ok = False
            else:
                print('[OK] libapp.so: %s (%dKB)' % (abi, size_kb))
    if not libflutter:
        print('[FAIL] libflutter.so 缺失')
        ok = False
    else:
        print('[OK] libflutter.so:', ', '.join(n.split('/')[1] for n in libflutter))
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
