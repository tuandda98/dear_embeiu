import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_question_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'animated_couple_name.dart';
import 'compose_pill.dart';
import 'content_card.dart';
import 'love_lottie.dart';

/// The "Hôm nay của chúng mình" ritual card (Home v3, 2026-06-10).
///
/// UX upgrades (2026-06-15):
/// - Whole card tappable (states A & B) via transparent Material overlay.
/// - Redesigned answer bottom sheet: gradient header, countdown char counter,
///   gradient send button — emotional, not just functional.
class TodayRitualCard extends StatefulWidget {
  const TodayRitualCard({super.key, required this.couple});

  final Couple couple;

  @override
  State<TodayRitualCard> createState() => _TodayRitualCardState();
}

class _TodayRitualCardState extends State<TodayRitualCard> {
  late final ConfettiController _confetti = ConfettiController(
    duration: const Duration(milliseconds: 600),
  );

  // Provider we listen to for the live reveal (partner's answer landing). Held
  // so we can detach the listener in dispose.
  DailyQuestionProvider? _daily;

  bool _confettiPlayed = false;
  bool _showRevealLottie = false;
  bool _revealExpanded = false;

  // Per-day guard (user 2026-06-19): the reveal celebration must play AT MOST
  // ONCE a day, not on every app open. On a cold start the provider re-derives
  // hasRevealed false→true, which the in-session trigger below would mistake for
  // a fresh reveal — so we also persist the date we last celebrated for this
  // couple in Hive and never replay it the same day.
  static const String _boxName = 'app_settings';
  bool _seenLoaded = false;
  bool _revealSeenToday = false;

  String get _revealSeenKey => 'dq_reveal_seen_${widget.couple.id}';

  String get _todayKey {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final daily = context.read<DailyQuestionProvider>();
    _daily = daily;
    _confettiPlayed = daily.hasRevealed;
    _revealExpanded = !daily.hasRevealed;
    // Trigger the reveal celebration from a provider listener — the moment the
    // partner's answer actually lands — instead of running side-effects inside
    // build(). The old in-build trigger re-evaluated on every rebuild and made
    // the transition stutter ("đơ").
    daily.addListener(_onDailyChanged);
    _loadRevealSeen();
  }

  void _onDailyChanged() => _maybeCelebrateReveal();

  /// Fires the once-a-day reveal celebration exactly once, guarded so it never
  /// replays on a rebuild or a cold-start false→true re-derivation. Safe to call
  /// from the provider listener or right after the per-day marker loads.
  void _maybeCelebrateReveal() {
    if (!mounted || _confettiPlayed || !_seenLoaded || _revealSeenToday) {
      return;
    }
    final daily = _daily;
    if (daily == null || !daily.hasRevealed) {
      return;
    }

    _confettiPlayed = true;
    _revealSeenToday = true;
    _stampRevealSeen();
    setState(() {
      _showRevealLottie = true;
      _revealExpanded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confetti.play();
    });
    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) setState(() => _showRevealLottie = false);
    });
  }

  Future<void> _loadRevealSeen() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      final stored = box.get(_revealSeenKey);
      if (!mounted) return;
      setState(() {
        _revealSeenToday = stored == _todayKey;
        _seenLoaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _seenLoaded = true);
    }
    // Both may have already answered before this marker loaded (a reveal that
    // raced the Hive read) — celebrate now, still gated by the once-a-day guard.
    _maybeCelebrateReveal();
  }

  Future<void> _stampRevealSeen() async {
    try {
      final box = await Hive.openBox<dynamic>(_boxName);
      await box.put(_revealSeenKey, _todayKey);
    } catch (_) {
      // Best-effort — worst case it celebrates once more next launch.
    }
  }

  @override
  void dispose() {
    _daily?.removeListener(_onDailyChanged);
    _confetti.dispose();
    super.dispose();
  }

  String _partnerName(AppLocalizations l10n) {
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final couple = widget.couple;
    final name = (myUid != null && myUid != couple.createdByUserId)
        ? couple.person1Name
        : couple.person2Name;
    final trimmed = name.trim();
    return trimmed.isNotEmpty ? trimmed : l10n.posterNameFallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final daily = context.watch<DailyQuestionProvider>();
    final langCode = Localizations.localeOf(context).languageCode;
    final isWaiting = widget.couple.isWaitingForPartner;
    final partnerName = _partnerName(l10n);

    // The reveal celebration is triggered from _onDailyChanged (a live provider
    // update), NOT here — build() must stay side-effect free so the transition
    // renders smoothly.

    // States A & B: nobody answered / partner answered first → whole card opens
    // the answer sheet.
    final canTapCard = !daily.hasAnswered;

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // ── Content card ──────────────────────────────────────────────────────
        ContentCard(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildQuestionSection(
                l10n,
                daily,
                langCode,
                partnerName,
                isWaiting,
              ),
            ),
          ),
        ),

        // ── Tappable overlay (states A & B only) ─────────────────────────────
        // Sits above ContentCard so the InkWell ripple renders on the white
        // surface; below Confetti/Lottie so they remain purely decorative.
        if (canTapCard)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: _openAnswerSheet,
                splashColor: AppColors.accentRose.withValues(alpha: 0.05),
                highlightColor: AppColors.accentRose.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

        // ── Decorative overlays (ignore pointer — visual only) ────────────────
        IgnorePointer(
          child: ConfettiWidget(
            confettiController: _confetti,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 14,
            maxBlastForce: 14,
            minBlastForce: 6,
            emissionFrequency: 0.0,
            gravity: 0.25,
            shouldLoop: false,
            colors: const [
              AppColors.accentRose,
              AppColors.accentLavender,
              AppColors.accentCoral,
              AppColors.white,
            ],
          ),
        ),
        if (_showRevealLottie)
          const IgnorePointer(
            child: Positioned(
              top: -8,
              child: LoveLottie(slot: LoveLottieSlot.dailyReveal, height: 120),
            ),
          ),
      ],
    );
  }

  // ── Question section ─────────────────────────────────────────────────────────

  List<Widget> _buildQuestionSection(
    AppLocalizations l10n,
    DailyQuestionProvider daily,
    String langCode,
    String partnerName,
    bool isWaiting,
  ) {
    final question = daily.todayQuestion(langCode);
    return [
      Text(
        question,
        style: AppTheme.displaySerif(
          size: 21,
          weight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.25,
          letterSpacing: -0.2,
        ),
      ),
      const SizedBox(height: 14),
      ..._buildQuestionBody(l10n, daily, question, partnerName, isWaiting),
    ];
  }

  List<Widget> _buildQuestionBody(
    AppLocalizations l10n,
    DailyQuestionProvider daily,
    String question,
    String partnerName,
    bool isWaiting,
  ) {
    // D. Revealed
    if (daily.hasRevealed) {
      if (!_revealExpanded) {
        return [
          _inlineRow(
            leading: const AnimatedHeartIcon(
              size: 18,
              color: AppColors.accentRose,
            ),
            label: l10n.dailyBothAnsweredToday,
            action: l10n.dailyReadAgain,
            onTap: () => setState(() => _revealExpanded = true),
          ),
        ];
      }
      final mine = daily.myAnswer?.text.trim() ?? '';
      final theirs = daily.partnerAnswer?.text.trim() ?? '';
      return [
        _answerBlock(l10n.dailyQuestionYourAnswerLabel, mine, mine: true),
        const SizedBox(height: 10),
        _answerBlock(
          l10n.dailyQuestionPartnerAnswerLabel(partnerName),
          theirs,
          mine: false,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: _textLink(
            l10n.dailyCollapse,
            onTap: () => setState(() => _revealExpanded = false),
          ),
        ),
      ];
    }

    // C. I answered, partner hasn't yet
    if (daily.hasAnswered) {
      final mine = daily.myAnswer?.text.trim() ?? '';
      final waitingFor = isWaiting
          ? l10n.dailyQuestionWaitingPartner
          : l10n.dailyQuestionAnsweredWaiting(partnerName);
      return [
        _answerBlock(l10n.dailyQuestionYourAnswerLabel, mine, mine: true),
        const SizedBox(height: 12),
        Text(
          waitingFor,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ];
    }

    // B. Partner answered first — a clean "locked" teaser. The old version blurred
    // the partner's real (near-black) text over a light surface, which rendered a
    // muddy grey-brown smudge and re-ran an expensive per-frame ImageFilter on the
    // live transition (the "đơ + màu nâu" bug). Redaction bars in the brand
    // lavender read just as clearly as "hidden answer" and cost nothing to paint.
    final teaser = daily.partnerAnswer;
    if (teaser != null) {
      return [
        _lockedTeaser(l10n, partnerName),
        const SizedBox(height: 12),
        ComposePill(
          label: l10n.dailyAnswerToReveal,
          emphasized: true,
          onTap: _openAnswerSheet,
        ),
      ];
    }

    // Waiting for partner (single player preview)
    if (isWaiting) {
      return [
        Text(
          l10n.dailyQuestionPairedFirst,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ];
    }

    // A. Nobody answered yet
    return [ComposePill(label: l10n.dailyTapToAnswer, onTap: _openAnswerSheet)];
  }

  // ── Answer sheet ─────────────────────────────────────────────────────────────

  Future<void> _openAnswerSheet() async {
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    final daily = context.read<DailyQuestionProvider>();
    final langCode = Localizations.localeOf(context).languageCode;

    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DailyAnswerSheet(
        question: daily.todayQuestion(langCode),
        l10n: l10n,
      ),
    );

    if (sent != true || !mounted) return;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.dailyQuestionSent)));
  }

  // ── Shared bits ──────────────────────────────────────────────────────────────

  Widget _inlineRow({
    required Widget leading,
    required String label,
    required String action,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _textLink(action, onTap: onTap),
            ],
          ),
        ),
      ),
    );
  }

  /// "Locked" preview shown when the partner answered first: brand-lavender
  /// redaction bars (fake hidden text) + a lock row. No blur, no dark text — so
  /// it never smudges into a brown blotch and paints in a single cheap frame.
  Widget _lockedTeaser(AppLocalizations l10n, String partnerName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accentLavender.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.accentLavender.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _redactBar(1.0),
          const SizedBox(height: 9),
          _redactBar(0.88),
          const SizedBox(height: 9),
          _redactBar(0.55),
          const SizedBox(height: 14),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusLinear.lock,
                size: 15,
                color: AppColors.accentLoveDeep,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.dailyPartnerAnsweredTeaser(partnerName),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _redactBar(double widthFactor) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: 11,
        decoration: BoxDecoration(
          color: AppColors.accentLavender.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }

  Widget _textLink(String label, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentLoveDeep,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _answerBlock(String label, String text, {required bool mine}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine
            ? AppColors.surfaceLight
            : AppColors.accentLavender.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: mine
                  ? AppColors.accentLoveDeep
                  : AppColors.accentLavenderDeep,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Answer bottom sheet (redesign 2026-06-15)
// ─────────────────────────────────────────────────────────────────────────────

class _DailyAnswerSheet extends StatefulWidget {
  const _DailyAnswerSheet({required this.question, required this.l10n});

  final String question;
  final AppLocalizations l10n;

  @override
  State<_DailyAnswerSheet> createState() => _DailyAnswerSheetState();
}

class _DailyAnswerSheetState extends State<_DailyAnswerSheet> {
  static const int _maxChars = 280;
  final TextEditingController _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final ok = await context.read<DailyQuestionProvider>().submit(text);
    if (!mounted) return;
    navigator.pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final remaining = _maxChars - _ctrl.text.characters.length;
    final isReady = _ctrl.text.trim().isNotEmpty && !_submitting;

    // Countdown colour: normal → warning at 50 → danger at 20
    final countColor = remaining <= 20
        ? AppColors.error
        : remaining <= 50
        ? AppColors.warning
        : AppColors.textTertiary;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Handle ──────────────────────────────────────────────────────
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Gradient header strip ────────────────────────────────────────
            _SheetHeader(question: widget.question, l10n: widget.l10n),

            // ── Text field ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.accentRose.withValues(alpha: 0.12),
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: TextField(
                  controller: _ctrl,
                  maxLength: _maxChars,
                  maxLines: null,
                  minLines: 4,
                  autofocus: true,
                  textInputAction: TextInputAction.newline,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.55,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.l10n.dailyQuestionHint,
                    hintStyle: TextStyle(
                      color: AppColors.textTertiary.withValues(alpha: 0.7),
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                    // Kill ALL border states so the theme's focusedBorder
                    // (red) doesn't bleed through our custom container.
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            ),

            // ── Footer: countdown + send ─────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, safeBottom + 16),
              child: Row(
                children: [
                  // Countdown — only shown once the user starts typing.
                  AnimatedOpacity(
                    opacity: remaining < _maxChars ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        color: countColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      child: Text('$remaining / $_maxChars'),
                    ),
                  ),
                  const Spacer(),
                  // Send button — gradient pill
                  _SendButton(
                    l10n: widget.l10n,
                    enabled: isReady,
                    loading: _submitting,
                    onTap: _submit,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sheet sub-widgets ──────────────────────────────────────────────────────────

/// Gradient header: heart badge + "Câu hỏi hôm nay" label + question text.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.question, required this.l10n});

  final String question;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: AppColors.sunsetRomance,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppColors.softCardShadow(opacity: 0.20)],
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row
          Row(
            children: [
              const Icon(
                IconsaxPlusBold.lovely,
                size: 16,
                color: AppColors.white,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.dailyQuestionLabel,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Question text on gradient
          Text(
            question,
            style: AppTheme.displaySerif(
              size: 18,
              weight: FontWeight.w600,
              color: AppColors.white,
              height: 1.3,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient pill send button with loading state.
class _SendButton extends StatelessWidget {
  const _SendButton({
    required this.l10n,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  final AppLocalizations l10n;
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: enabled ? 1.0 : 0.45,
      duration: const Duration(milliseconds: 200),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.sunsetRomance : null,
          color: enabled ? null : AppColors.textTertiary.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(999),
          boxShadow: enabled ? [AppColors.softCardShadow(opacity: 0.20)] : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(999),
            splashColor: Colors.white.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
              child: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.white,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.dailyQuestionSend,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          IconsaxPlusBold.send_2,
                          size: 15,
                          color: AppColors.white,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
