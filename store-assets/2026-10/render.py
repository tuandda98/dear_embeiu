# Dựng ảnh store từ khung quay thật của app (shots/, cắt từ clip robot quay simulator — feature promo-video).
# python3 render.py [tên-shot…] → asc/ (1290×2796) + play/ (1290×2294). Cần Google Chrome.
import subprocess,urllib.parse,sys,os
S=os.path.dirname(os.path.abspath(__file__))
CH='/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
SHOTS=[
 ('s2-question','dark','Câu hỏi hằng ngày','Mỗi ngày<br>một câu hỏi','Cả hai cùng trả lời xong mới thấy câu của nhau.'),
 ('s3-mood','dark','Tâm trạng','Hôm nay<br>bạn thấy sao?','Chọn một tâm trạng, người ấy biết ngay.'),
 ('s4-stars','light','Cây Tình Yêu','Chòm sao<br>của hôm nay','Hỏi han, nhắn tin, chia sẻ tâm trạng. Mỗi việc nhỏ thắp một ngôi sao.'),
 ('s5-flowers','light','Cột mốc','Mỗi cột mốc<br>nở một bông hoa','100 ngày, 1.000 ngày, 25 tấm ảnh chung. Cành hoa lớn dần theo chúng mình.'),
 ('s6-sleep','light','Giấc ngủ','Đêm qua<br>ngủ ngon không?','Lịch trăng giấc ngủ của cả hai, chỉ hiện khi bạn bật chia sẻ.'),
 ('s7-gallery','dark','Kỷ niệm','Album chỉ<br>hai bạn xem được','Chụp một tấm, viết vài dòng là thành kỷ niệm.'),
]
T={'asc':dict(w=1290,h=2796,ty=140,fs=112,ss=52,pw=1130,py=800),
   'play':dict(w=1290,h=2294,ty=110,fs=100,ss=46,pw=1060,py=700)}
only=sys.argv[1:]
for tgt,cfg in T.items():
  os.makedirs(f'{S}/{tgt}',exist_ok=True)
  for i,(img,bg,eb,t,s) in enumerate(SHOTS):
    if only and img not in only: continue
    q=dict(cfg,img=f'file://{S}/shots/{img}.png',bg=bg,eb=eb,t=t,s=s)
    url=f'file://{S}/shot.html?'+urllib.parse.urlencode(q)
    out=f'{S}/{tgt}/{i+2:02d}-{img}.png'
    subprocess.run([CH,'--headless=new','--disable-gpu','--hide-scrollbars','--allow-file-access-from-files','--force-device-scale-factor=1',
      f'--window-size={cfg["w"]},{cfg["h"]}',f'--screenshot={out}','--virtual-time-budget=3000',url],check=True,capture_output=True)
    print(out)
