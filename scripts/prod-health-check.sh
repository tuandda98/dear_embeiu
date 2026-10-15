#!/usr/bin/env bash
# Kiểm tra nhanh sức khoẻ backend (mặc định PROD): billing account có MỞ không, Storage ghi được không,
# Cloud Functions có khởi động không. Credential = refresh-token của `npx firebase-tools login` (không cần gcloud).
# Dùng: scripts/prod-health-check.sh [project]   (mặc định tonyembeiu; DEV: tonyembeiu-dev)
set -euo pipefail
PROJECT="${1:-tonyembeiu}"
CFG="$HOME/.config/configstore/firebase-tools.json"
RT=$(node -e "console.log(JSON.parse(require('fs').readFileSync('$CFG','utf8')).tokens.refresh_token)")
TOK=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d client_id=563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com \
  -d client_secret=j9iVZfS8kkCEFUPaAeJV0sAi -d refresh_token="$RT" -d grant_type=refresh_token \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>console.log(JSON.parse(s).access_token))")
H=(-H "Authorization: Bearer $TOK")

echo "== [$PROJECT] billing =="
ACC=$(curl -s "${H[@]}" "https://cloudbilling.googleapis.com/v1/projects/$PROJECT/billingInfo" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);console.log((j.billingAccountName||'').replace('billingAccounts/',''))})")
echo "  account: ${ACC:-<none>}"
if [ -n "$ACC" ]; then
  curl -s "${H[@]}" "https://cloudbilling.googleapis.com/v1/billingAccounts/$ACC" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);console.log('  open:',j.open,'|',j.displayName||j.error&&j.error.message); if(!j.open) console.log('  ❌ ACCOUNT ĐÓNG → relink: curl -X PUT .../projects/$PROJECT/billingInfo -d {billingAccountName:billingAccounts/<id mở>}')})"
fi
echo "  các account đang mở:"
curl -s "${H[@]}" https://cloudbilling.googleapis.com/v1/billingAccounts | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{for(const a of JSON.parse(s).billingAccounts||[])console.log('   ',a.open?'✅':'❌',a.name.replace('billingAccounts/',''),a.displayName)})"

echo "== [$PROJECT] storage write probe =="
BUCKET=$(curl -s "${H[@]}" "https://firebasestorage.googleapis.com/v1beta/projects/$PROJECT/buckets" | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{const j=JSON.parse(s);console.log(((((j.buckets||[])[0]||{}).name)||'').split('/').pop())})")
echo "  bucket: $BUCKET"
curl -s -o /dev/null -w "  upload http %{http_code}\n" -X POST "${H[@]}" -H "Content-Type: text/plain" --data-binary "probe $(date -u +%FT%TZ)" \
  "https://storage.googleapis.com/upload/storage/v1/b/$BUCKET/o?uploadType=media&name=_healthcheck/probe.txt"
curl -s -o /dev/null -w "  delete http %{http_code}\n" -X DELETE "${H[@]}" "https://storage.googleapis.com/storage/v1/b/$BUCKET/o/_healthcheck%2Fprobe.txt"

echo "== [$PROJECT] cloud functions cold-start probe (mong 401 = code hàm chạy; 5xx = hạ tầng chết) =="
curl -s "${H[@]}" "https://run.googleapis.com/v2/projects/$PROJECT/locations/us-central1/services" \
  | node -e "let s='';process.stdin.on('data',d=>s+=d).on('end',()=>{for(const x of JSON.parse(s).services||[])if(/deleteaccount|leavecouplecleanup|generatedailyquestion|migratelovenotestochat/.test(x.name))console.log(x.name.split('/').pop(),x.uri)})" \
  | while read -r N U; do printf "  %s %s\n" "$(curl -s -o /dev/null -m 60 -w '%{http_code}' -X POST -H 'Content-Type: application/json' "$U" -d '{"data":{}}')" "$N"; done
