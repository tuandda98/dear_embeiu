#!/usr/bin/env bash
# Nhập khoá Sign in with Apple (.p8) vào Firebase (Authentication → Apple → OAuth code flow) để app thu hồi
# được token Apple khi người dùng xoá tài khoản. CHỦ TÀI KHOẢN TỰ CHẠY: Claude không được tự nhập khoá bí mật.
# Dùng: scripts/set-apple-signin-key.sh <file.p8> <KEY_ID> [project]   (project mặc định tonyembeiu = PROD)
# client_id = bundle ID vì app chỉ đăng nhập Apple trên iPhone; khoá phải gắn primary App ID com.tony.dearembeiu.
# Credential = refresh-token của `npx firebase-tools login`. Không in nội dung khoá ra màn hình.
set -euo pipefail
P8="${1:?thiếu đường dẫn file .p8}"; KEY_ID="${2:?thiếu Key ID}"; PROJECT="${3:-tonyembeiu}"
TEAM_ID=4UBR69C227; CLIENT_ID=com.tony.dearembeiu
[ -f "$P8" ] || { echo "✗ không thấy $P8"; exit 1; }
CFG="$HOME/.config/configstore/firebase-tools.json"
RT=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$CFG','utf8')).tokens.refresh_token)")
TOK=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d client_id=563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com \
  -d client_secret=j9iVZfS8kkCEFUPaAeJV0sAi -d refresh_token="$RT" -d grant_type=refresh_token \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log(JSON.parse(s).access_token||''))")
[ -n "$TOK" ] || { echo "✗ không lấy được token — chạy lại: npx firebase-tools login"; exit 1; }
URL="https://identitytoolkit.googleapis.com/admin/v2/projects/$PROJECT/defaultSupportedIdpConfigs/apple.com"
MASK="clientId,appleSignInConfig.codeFlowConfig.keyId,appleSignInConfig.codeFlowConfig.teamId,appleSignInConfig.codeFlowConfig.privateKey"
# Khoá đi qua stdin của curl, không nằm trên dòng lệnh (ps không thấy).
P8="$P8" KEY_ID="$KEY_ID" TEAM_ID="$TEAM_ID" CLIENT_ID="$CLIENT_ID" node -e "
const fs = require('fs'), e = process.env;
process.stdout.write(JSON.stringify({clientId: e.CLIENT_ID, appleSignInConfig: {codeFlowConfig: {
  keyId: e.KEY_ID, teamId: e.TEAM_ID, privateKey: fs.readFileSync(e.P8, 'utf8').trim()}}}));" \
| curl -s -X PATCH "$URL?updateMask=$MASK" -H "Authorization: Bearer $TOK" -H "X-Goog-User-Project: $PROJECT" \
    -H "Content-Type: application/json" --data-binary @- \
| node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);
  if (j.error) { console.log('✗ ' + j.error.message); process.exit(1); }
  const c = (j.appleSignInConfig || {}).codeFlowConfig || {};
  console.log('✓ $PROJECT — Apple: clientId=' + j.clientId + ' · keyId=' + c.keyId + ' · teamId=' + c.teamId
    + ' · privateKey=' + (c.privateKey ? 'đã lưu' : 'THIẾU'));})"
