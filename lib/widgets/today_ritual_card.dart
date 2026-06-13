import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
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

/// The "Hôm nay của chúng mình" ritual card (Home v3, 2026-06-10): today's
/// question, tap-to-compose. Design principles applied:
///
/// 1. Question = tap-to-compose — a pill opens the answer bottom sheet.
/// 2. Blur-teaser — when the partner answered first, their answer shows
///    BLURRED with an unlock hint (the strongest answer motivator).
/// 3. Collapsing done-state — after a (stale) reveal the question block
///    shrinks to one line; a fresh reveal stays expanded and celebrates.
///
/// The love-note section was REMOVED (user 2026-06-11) — messaging now lives
/// entirely in the messenger-style chat (LoveNoteHistoryScreen, reached via
/// the Profile memory chest); the journal/history archive links moved there
/// too (Profile v2, 2026-06-11). Home only carries today's question ritual.
class TodayRitualCard extends StatefulWidget {
  const TodayRitualCard({super.key, required this.couple});

  final Couple couple;

  @override
  State<TodayRitualCard> createState() => _TodayRitualCardState();
}

class _TodayRitualCardState extends State<TodayRitualCard> {
  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 600));

  // One-shot reveal celebration guards (same protocol as the old card: only a
  // reveal that HAPPENS while watching celebrates; reopening Home after both
  // answered must not surprise the user).
  bool _confettiPlayed = false;
  bool _showRevealLottie = false;

  /// Whether the revealed answers are expanded. Starts collapsed when the card
  /// is born already-revealed (done-state should be small); flips to true on a
  /// fresh reveal so the user reads the answers in the moment.
  bool _revealExpanded = false;

  @override
  void initState() {
    super.initState();
    final daily = context.read<DailyQuestionProvider>();
    _confettiPlayed = daily.hasRevealed;
    _revealExpanded = !daily.hasRevealed;
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Partner's display name: the viewer's counterpart in the couple, resolved
  /// from the signed-in uid (creator == person1).
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

    // Fresh reveal while watching → celebrate once and expand.
    if (daily.hasRevealed && !_confettiPlayed) {
      _confettiPlayed = true;
      _showRevealLottie = true;
      _revealExpanded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confetti.play();
        }
      });
      Future.delayed(const Duration(milliseconds: 2600), () {
        if (mounted) {
          setState(() => _showRevealLottie = false);
        }
      });
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Solid white reading surface (ContentCard, B4) — the design system
        // reserves glass for decorative blocks, not content-heavy cards.
        ContentCard(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildQuestionSection(l10n, daily, langCode, partnerName,
                    isWaiting),
              ],
            ),
          ),
        ),
        ConfettiWidget(
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
        // One-shot unlock moment (feature lottie-moments) — auto-hidden so it
        // never sits frozen on its last frame.
        if (_showRevealLottie)
          const Positioned(
            top: -8,
            child: LoveLottie(
              slot: LoveLottieSlot.dailyReveal,
              height: 120,
            ),
          ),
      ],
    );
  }


  // ── Daily question ─────────────────────────────────────────────────────────

  List<Widget> _buildQuestionSection(
    AppLocalizations l10n,
    DailyQuestionProvider daily,
    String langCode,
    String partnerName,
    bool isWaiting,
  ) {
    final question = daily.todayQuestion(langCode);

    return [
      Row(
        children: [
          const Icon(LucideIcons.heartHandshake,
              color: AppColors.accentRose, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.dailyQuestionLabel,
              // Same voice as the love-note header — two sections of equal
              // rank inside one card must share one header style.
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
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
    // D. Revealed — collapsed one-liner or expanded answers.
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

    // C. I answered, partner hasn't yet.
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

    // B. Partner answered first — blurred teaser + unlock pill.
    final teaser = daily.partnerAnswer;
    if (teaser != null) {
      return [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            children: [
              // Blur the real text; exclude it from semantics so a screen
              // reader can't leak the unrevealed answer.
              ExcludeSemantics(
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    color: AppColors.surfaceLight,
                    child: Text(
                      teaser.text,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  alignment: Alignment.center,
                  color: AppColors.white.withValues(alpha: 0.10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.lock,
                          size: 15, color: AppColors.accentLoveDeep),
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ComposePill(
          label: l10n.dailyAnswerToReveal,
          emphasized: true,
          onTap: _openAnswerSheet,
        ),
      ];
    }

    // Waiting for a partner: the question is a PREVIEW, not a form — a
    // "question for two" doesn't exist yet, so there is nothing to answer
    // into (user 2026-06-10). The banner above carries the invite CTA.
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

    // A. Nobody answered yet — quiet compose pill (no raw form on Home).
    return [
      ComposePill(
        label: l10n.dailyTapToAnswer,
        onTap: _openAnswerSheet,
      ),
    ];
  }

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

    if (sent != true || !mounted) {
      return;
    }
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.dailyQuestionSent)),
    );
  }

  // ── Shared bits ────────────────────────────────────────────────────────────
  // (The tap-to-compose pill moved to the shared ComposePill widget, B8.)

  /// Compact done-state row: pulsing heart + label + trailing action.
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

  /// Answer block, SAME two-tone language as the journal screen so the pair
  /// reads identically across the app: mine = surfaceLight + rose label,
  /// partner = lavender tint + lavender label (couple-journal convention).
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

/// Bottom-sheet composer for today's answer (tap-to-compose). Shows the
/// question while typing; pops `true` after a successful submit.
class _DailyAnswerSheet extends StatefulWidget {
  const _DailyAnswerSheet({required this.question, required this.l10n});

  final String question;
  final AppLocalizations l10n;

  @override
  State<_DailyAnswerSheet> createState() => _DailyAnswerSheetState();
}

class _DailyAnswerSheetState extends State<_DailyAnswerSheet> {
  static const int _maxChars = 280;
  final TextEditingController _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _submitting) {
      return;
    }
    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final ok = await context.read<DailyQuestionProvider>().submit(text);
    if (!mounted) {
      return;
    }
    navigator.pop(ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          color: AppColors.cardSurface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(LucideIcons.heartHandshake,
                      color: AppColors.accentRose, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.dailyQuestionLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.question,
                style: AppTheme.displaySerif(
                  size: 19,
                  weight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _controller,
                maxLength: _maxChars,
                maxLines: 5,
                minLines: 3,
                autofocus: true,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.dailyQuestionHint,
                  counterText: l10n.dailyQuestionCharCount(
                    _controller.text.characters.length,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed:
                      (_submitting || _controller.text.trim().isEmpty)
                          ? null
                          : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(l10n.dailyQuestionSend),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
