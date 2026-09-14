#!/usr/bin/env bash
# Upload IPA lên App Store Connect bằng app Transporter (GUI) — tự động hoá bằng AppleScript + CGEvent.
# Vì sao không dùng altool: máy không có ASC API key/app-specific password; Transporter đã đăng nhập sẵn Apple ID.
# Điều kiện: Terminal chạy Claude có quyền Accessibility (System Events keystroke) — đã có trên máy nhà.
# Dùng: scripts/store-upload/upload-ios-transporter.sh [path.ipa]   (mặc định build/ios/ipa/dear_embeiu.ipa)
# Sau khi chạy: Transporter hiện "ĐANG TẢI LÊN…" → chờ tới "ĐÃ CHUYỂN GIAO"; build lên TestFlight sau ~5–15'.
set -euo pipefail
IPA="${1:-build/ios/ipa/dear_embeiu.ipa}"; IPA="$(cd "$(dirname "$IPA")" && pwd)/$(basename "$IPA")"
[ -f "$IPA" ] || { echo "✗ không thấy $IPA"; exit 1; }
D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; B="$D/.bin"; mkdir -p "$B"
for t in click winbounds winlist; do [ -x "$B/$t" ] || swiftc -O -o "$B/$t" "$D/$t.swift" 2>/dev/null; done
snap() { "$B/winlist" Transporter | awk -F'\t' '$3=="[]" && $2+0>=0 {print}' | sort -t' ' -k3 -rn | head -1; }

echo "→ mở Transporter"; open -a Transporter; sleep 4
# Chờ đăng nhập xong (cửa sổ chính rộng ≥1000px xuất hiện)
for i in $(seq 1 30); do MAIN=$("$B/winlist" Transporter | awk -F'\t' '{split($2,a," "); if (a[3]+0 >= 1000) print $1}' | head -1); [ -n "$MAIN" ] && break; sleep 2; done
[ -n "$MAIN" ] || { echo "✗ Transporter chưa đăng nhập / không thấy cửa sổ chính — mở tay rồi chạy lại"; exit 1; }
echo "→ cửa sổ chính id=$MAIN"

# ⚠️ KHÔNG keystroke đường dẫn: bộ gõ Telex biến "aab"→"âb". Luôn dán qua clipboard.
printf '%s' "$IPA" | pbcopy
osascript -e 'tell application "Transporter" to activate' -e 'delay 1' \
  -e 'tell application "System Events" to tell process "Transporter" to click menu item "Thêm gói" of menu 1 of menu bar item "Tệp" of menu bar 1' -e 'delay 3'
"$B/winlist" Transporter | grep -q "\[Mở\]\|\[Open\]" || { echo "✗ hộp thoại Mở không hiện"; exit 1; }
osascript -e 'tell application "System Events" to tell process "Transporter"' \
  -e 'keystroke "g" using {command down, shift down}' -e 'delay 1.5' -e 'keystroke "a" using {command down}' -e 'keystroke "v" using {command down}' -e 'delay 1.5' -e 'keystroke return' -e 'delay 3' -e 'end tell'
# Nút "Mở" của panel: panel là process riêng (không có AX) → click theo bounds góc dưới phải.
PANEL=$("$B/winlist" Transporter | grep "\[Mở\]\|\[Open\]" | cut -f1 | head -1)
if [ -n "$PANEL" ]; then read PX PY PW PH <<< "$("$B/winbounds" "$PANEL")"; "$B/click" "$(python3 -c "print(int($PX+0.936*$PW))")" "$(python3 -c "print(int($PY+0.933*$PH))")"; fi
sleep 12
"$B/winlist" Transporter | grep -q "\[Mở\]\|\[Open\]" && { echo "✗ panel Mở vẫn còn — kiểm tra tay"; exit 1; }
# Nút CHUYỂN GIAO của dòng đầu "Đang hoạt động": toạ độ tương đối theo layout Transporter 1600×816 (đo 2026-09-13).
read X Y W H <<< "$("$B/winbounds" "$MAIN")"
osascript -e 'tell application "Transporter" to activate' -e 'delay 1'
# Tỉ lệ đo lại 2026-09-14 trên màn hình thật (nút ở 0.899·W, 0.219·H); 0.183 cũ trúng mép trên → trượt.
"$B/click" "$(python3 -c "print(int($X + 0.899*$W))")" "$(python3 -c "print(int($Y + 0.219*$H))")"
sleep 5; screencapture -x -l "$MAIN" /tmp/transporter-after-deliver.png
echo "✓ đã bấm CHUYỂN GIAO — xem /tmp/transporter-after-deliver.png (phải thấy 'ĐANG TẢI LÊN ỨNG DỤNG')"
