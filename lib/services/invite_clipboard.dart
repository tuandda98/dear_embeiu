import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import '../app/app_urls.dart';

/// Spots an invite link in the clipboard for the Setup screen (feature
/// pairing-funnel, PF9 / PF12 / PF13). The get page copies the whole link
/// (`https://dearembeiu.com/get?code=XXXXXX`) when the invitee taps download,
/// so only that link counts — a bare 6-character string could be an OTP.
///
/// Never logs clipboard contents.
abstract final class InviteClipboard {
  static const MethodChannel _channel = MethodChannel('dear_embeiu/clipboard');

  // Hive `app_settings` is a Box<String> (opened in main()).
  static const String _boxName = 'app_settings';
  // iOS `UIPasteboard.changeCount` of the last content we READ. Reading is what
  // shows "Allow Paste", so one clipboard content never prompts twice.
  static const String _changeCountKey = 'invite_clipboard_change_count';
  // Codes already offered (comma-joined): each code is asked exactly once.
  static const String _askedKey = 'invite_clipboard_asked';

  static final Uri _base = Uri.parse(AppUrls.inviteBase);

  // Host (+ optional scheme / www.) must not follow a URL character, so it is
  // neither glued to another domain nor nested inside another URL (path or
  // query); start, whitespace, brackets and quotes are fine. `code` may sit
  // anywhere in the query; exactly 6 alphanumerics.
  static final RegExp _inviteLink = RegExp(
    r'(?<![a-z0-9._~:/?#@!$&*+,;=%-])(?:https?://)?(?:www\.)?'
    '${RegExp.escape(_base.host + _base.path)}'
    r'\?(?:[^\s#&]*&)*code=([a-z0-9]{6})(?![a-z0-9])',
    caseSensitive: false,
  );

  /// The invite code inside [text] (upper-cased), or null when [text] holds no
  /// `dearembeiu.com/get?…code=XXXXXX` link. Also used on the Setup code field
  /// when someone pastes the whole link.
  static String? parseInviteCode(String text) =>
      _inviteLink.firstMatch(text)?.group(1)?.toUpperCase();

  /// The invite code waiting in the clipboard, or null (nothing there, not an
  /// invite link, already offered, or any error).
  static Future<String?> peekInviteCode() async {
    final box = _box;
    if (box == null) {
      return null;
    }
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // Native first: detectPatterns tells "there is a URL" without reading
        // it, so plain text in the clipboard never triggers the prompt.
        final probe = await _channel.invokeMapMethod<String, Object?>('probe');
        if (probe == null || probe['hasUrl'] != true) {
          return null;
        }
        final changeCount = '${probe['changeCount']}';
        if (box.get(_changeCountKey) == changeCount) {
          return null;
        }
        await box.put(_changeCountKey, changeCount);
      } else if (!await Clipboard.hasStrings()) {
        return null;
      }
      final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
      final code = text == null ? null : parseInviteCode(text);
      if (code == null || _asked(box).contains(code)) {
        return null;
      }
      return code;
    } catch (_) {
      return null;
    }
  }

  /// Remembers that [code] was offered, whatever the answer (PF9).
  static Future<void> markAsked(String code) async {
    final box = _box;
    if (box == null) {
      return;
    }
    try {
      // ponytail: unbounded list — a person sees a handful of codes, ever.
      await box.put(_askedKey, {..._asked(box), code}.join(','));
    } catch (_) {
      // Worst case the same code is offered once more.
    }
  }

  static Set<String> _asked(Box<String> box) =>
      (box.get(_askedKey) ?? '').split(',').where((c) => c.isNotEmpty).toSet();

  // Null when the box isn't open (never in the app; main() opens it) — then
  // nothing is read, so nothing can be asked twice.
  static Box<String>? get _box =>
      Hive.isBoxOpen(_boxName) ? Hive.box<String>(_boxName) : null;
}
