// Mã lần chạy: truyền `-e RUN=...` để hai máy dùng chung; không truyền thì tự sinh.
output.run = (typeof RUN !== 'undefined' && RUN) ? String(RUN) : String(Date.now()).slice(-7);
