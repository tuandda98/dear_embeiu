#!/bin/bash
# assemble-index.mjs "hoist" thẻ <video data-frame-video="approved"> lên index.html và GHI ĐÈ file cảnh
# bằng comment → lần ghép sau không còn video. Chạy script này TRƯỚC mỗi lần assemble.
set -eu
cd "$(dirname "$0")"
python3 - <<'PY'
import re
frames={
 '03-cau-1-tam-trang':('f03-cau-1-tam-trang-video','assets/screen-mood.mp4','5.27'),
 '04-cau-2-giac-ngu':('f04-screen','assets/screen-sleep.mp4','5.27'),
 '05-cau-3-cau-hoi':('f05-screen','assets/screen-dq.mp4','5.28'),
 '06-con-so-van-co':('f06-screen','assets/screen-home.mp4','3.95'),
}
marker='<!-- approved frame video hoisted by assemble-index -->'
for fid,(vid,src,dur) in frames.items():
    p=f'compositions/frames/{fid}.html'; s=open(p).read()
    tag=(f'<video id="{vid}" data-frame-video="approved" src="{src}" data-start="0" data-duration="{dur}" '
         f'data-track-index="5" data-frame-video-x="240" data-frame-video-y="652" data-frame-video-width="600" '
         f'data-frame-video-height="1304" data-frame-video-fit="cover" muted playsinline></video>')
    if marker in s:
        s=s.replace(marker,tag,1); open(p,'w').write(s); print(fid,'restored')
    elif 'data-frame-video="approved"' in s:
        print(fid,'already has video')
    else:
        print(fid,'NO MARKER, NO VIDEO — check manually')
PY
