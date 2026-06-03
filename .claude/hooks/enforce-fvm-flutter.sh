#!/usr/bin/env bash
# Ép dùng `fvm flutter` / `fvm dart` thay vì `flutter`/`dart` TRẦN.
# Lý do: toolchain trần trên máy này là Flutter 3.5.4 -> analyze/build/test FAIL.
# fvm pin đúng version (xem .fvmrc -> "stable" = 3.41.6). Hook chạy bất kể
# permission mode nên là lớp đảm bảo thật sự, không phụ thuộc model có nhớ hay không.
#
# Cơ chế: đọc tool-input JSON từ stdin. Nếu lệnh Bash gọi `flutter`/`dart` ở đầu
# lệnh hoặc ngay sau ; && || (tức invocation TRẦN, KHÔNG có tiền tố `fvm `) -> deny
# qua JSON PreToolUse kèm gợi ý sửa. `fvm flutter`/`fvm dart` không khớp (vì
# flutter/dart đứng sau `fvm `, không phải đầu/separator) nên vẫn chạy bình thường.
#
# Cố ý KHÔNG `set -e`: chỉ chặn qua JSON deny, không bao giờ thoát mã lỗi ngoài ý muốn.
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
if printf '%s' "$cmd" | grep -qE '(^|[;&|][[:space:]]*)(flutter|dart)[[:space:]]'; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Dung `fvm flutter` / `fvm dart` thay vi `flutter`/`dart` tran. Bare toolchain o may nay la 3.5.4 -> se FAIL. Vi du: doi `flutter analyze` thanh `fvm flutter analyze`, `dart run ...` thanh `fvm dart run ...`."}}'
fi
exit 0
