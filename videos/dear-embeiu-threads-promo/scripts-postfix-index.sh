#!/bin/bash
# Sau assemble-index + transitions: bo góc 88px cho video màn hình đã hoist lên root
# (assembler chỉ sinh style chữ nhật; frame không che được vì video nằm trên frame).
set -eu
cd "$(dirname "$0")"
python3 - <<'PY'
import re
p='index.html'; s=open(p).read()
n=0
def fix(m):
    global n; n+=1
    return m.group(0).replace('object-fit:cover"','object-fit:cover;border-radius:88px;overflow:hidden"')
s2=re.sub(r'<video[^>]*data-frame-video-x[^>]*>|<video[^>]*style="position:absolute;left:240px;top:652px;width:600px;height:1304px;object-fit:cover"[^>]*>', fix, s)
# the assembler drops data-frame-video-* on hoist; match by the exact geometry instead
s2=s.replace('style="position:absolute;left:240px;top:652px;width:600px;height:1304px;object-fit:cover"','style="position:absolute;left:240px;top:652px;width:600px;height:1304px;object-fit:cover;border-radius:88px;overflow:hidden"')
cnt=s2.count('border-radius:88px;overflow:hidden')
open(p,'w').write(s2); print('rounded hoisted videos:',cnt)
PY
