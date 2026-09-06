import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

import '../services/catchup_service.dart';
import '../services/daily_question_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'content_card.dart';
import 'eyebrow_chip.dart';

/// Blocking "catch-up" gate (feature `catch-up`, 2026-09-05).
///
/// ⚠️ ACCOUNT-GATED to [CatchupService.gatedEmail] — the caller
/// (`home_screen.dart`) never opens it for anyone else. It is deliberately
/// UN-DISMISSABLE (no close button, no "later", `PopScope(canPop: false)`,
/// `barrierDismissible: false`): the whole point is to make em bé answer the
/// days she forgot so the couple streak can be repaired.
///
/// Copy is hardcoded Vietnamese (same rule as the personal reminder band in
/// [ReminderProvider]): one VN account only, so no ARB keys are spent on it.
class CatchupGate {
  const CatchupGate._();

  /// True while a gate is on screen — the caller uses this to never stack two.
  static bool get isShowing => _isShowing;
  static bool _isShowing = false;

  /// Identity of the gate currently shown; a stale dialog's `dispose` (which
  /// runs ~300ms after `showDialog` completes) only clears the guard when it
  /// still owns it.
  static Object? _token;

  /// Walks [days] (oldest first) one question at a time. Resolves when every
  /// day has been answered (the only way out).
  static Future<void> show(
    BuildContext context, {
    required String coupleId,
    required String myUid,
    required List<CatchupMissedDay> days,
    DailyQuestionService? service,
  }) async {
    if (_isShowing || days.isEmpty) {
      return;
    }
    _isShowing = true;
    final token = Object();
    _token = token;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        useSafeArea: false,
        barrierColor: AppColors.textPrimary.withValues(alpha: 0.55),
        builder: (_) => _CatchupGateDialog(
          coupleId: coupleId,
          myUid: myUid,
          days: days,
          service: service ?? DailyQuestionService(),
          token: token,
        ),
      );
    } finally {
      if (_token == token) {
        _isShowing = false;
        _token = null;
      }
    }
  }
}

class _CatchupGateDialog extends StatefulWidget {
  const _CatchupGateDialog({
    required this.coupleId,
    required this.myUid,
    required this.days,
    required this.service,
    required this.token,
  });

  final String coupleId;
  final String myUid;
  final List<CatchupMissedDay> days;
  final DailyQuestionService service;

  /// See [CatchupGate._token].
  final Object token;

  @override
  State<_CatchupGateDialog> createState() => _CatchupGateDialogState();
}

class _CatchupGateDialogState extends State<_CatchupGateDialog> {
  final TextEditingController _controller = TextEditingController();
  int _index = 0;
  bool _sending = false;

  @override
  void dispose() {
    // The route can be REMOVED (session revoked → pushNamedAndRemoveUntil)
    // without ever completing `showDialog`'s future, which would leave the
    // static guard stuck at true for the rest of the process.
    if (CatchupGate._token == widget.token) {
      CatchupGate._isShowing = false;
      CatchupGate._token = null;
    }
    _controller.dispose();
    super.dispose();
  }

  CatchupMissedDay get _day => widget.days[_index];

  String get _dayLabel {
    final d = _day.date.day.toString().padLeft(2, '0');
    final m = _day.date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    setState(() => _sending = true);
    try {
      // Firestore queues the write offline and `set()` then never resolves —
      // inside an un-dismissable dialog that would freeze the app. After the
      // timeout the write is still queued, so treat it as sent and move on.
      await widget.service
          .submitAnswer(
            coupleId: widget.coupleId,
            dateKey: _day.dateKey,
            uid: widget.myUid,
            text: text,
            backfill: true,
          )
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mạng chậm xíu, câu trả lời sẽ tự gửi khi có mạng 💌'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _sending = false);
      // Keep the gate up and let her retry — nothing was saved.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi chưa được, embe thử lại giúp anh By nha 🥺'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    final isLast = _index >= widget.days.length - 1;
    if (isLast) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _index++;
      _sending = false;
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: ContentCard(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const EyebrowChip(
                      label: 'ANH BY <3',
                      icon: IconsaxPlusBold.heart,
                    ),
                    const Spacer(),
                    Text(
                      '${_index + 1}/${widget.days.length}',
                      style: AppTheme.pageEyebrowStyle(alpha: 0.55),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Embe quên câu hỏi ngày $_dayLabel rồi nè 🥺',
                  style: AppTheme.sectionTitleStyle(),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trả lời bù cho anh By nha, xong là chuỗi của chúng mình lại '
                  'đẹp như cũ 💗',
                  style: AppTheme.sectionSubtitleStyle(),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _day.questionVi,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 280,
                  textCapitalization: TextCapitalization.sentences,
                  inputFormatters: [LengthLimitingTextInputFormatter(280)],
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 15,
                    height: 1.4,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Embe viết câu trả lời ở đây…',
                    filled: true,
                    fillColor: AppColors.white,
                    counterStyle: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.surfaceLight,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.surfaceLight,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(
                        color: AppColors.accentLove,
                        width: 1.4,
                      ),
                    ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed:
                        _sending || _controller.text.trim().isEmpty
                        ? null
                        : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentLove,
                      disabledBackgroundColor: AppColors.accentLove.withValues(
                        alpha: 0.35,
                      ),
                      foregroundColor: AppColors.white,
                      disabledForegroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Gửi cho anh By 💌',
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
