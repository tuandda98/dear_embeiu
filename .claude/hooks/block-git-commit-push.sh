#!/usr/bin/env bash
# Chặn `git commit` / `git push` NGAY CẢ KHI bypass permissions mode đang bật.
# Hook luôn chạy bất kể permission mode, nên đây là lớp đảm bảo thật sự (deny-rule
# trong bypass mode không phải lúc nào cũng đủ tin cậy, và không bắt được dạng
# `git -C <path> commit`).
#
# Cơ chế: đọc tool-input JSON từ stdin. Nếu lệnh Bash chứa `git ... commit` hoặc
# `git ... push` -> in quyết định "deny" cho PreToolUse (exit 0) -> call bị chặn,
# Claude nhận được lý do. Mọi lệnh khác: không in gì, exit 0 -> chạy bình thường.
#
# Cố ý KHÔNG dùng `set -e`: hook chỉ được chặn qua JSON deny; không bao giờ thoát
# với mã lỗi ngoài ý muốn (mã 2 = block, mã khác = lỗi non-blocking).
input=$(cat)
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)
if printf '%s' "$cmd" | grep -qiE '\bgit\b.*\b(commit|push)\b'; then
  printf '%s' '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"Bypass mode dang bat, nhung git commit va git push bi chan theo cau hinh. KHONG tu dong commit/push - hay bao user tu chay, hoac xin phep truoc khi thuc hien."}}'
fi
exit 0
