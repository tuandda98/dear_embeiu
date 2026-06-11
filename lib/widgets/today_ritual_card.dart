import 'dart:async';
import 'dart:ui';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/love_note.dart';
import '../providers/auth_provider.dart';
import '../providers/daily_question_provider.dart';
import '../providers/love_note_provider.dart';
import '../services/analytics_service.dart';
import '../screens/journal_screen.dart';
import '../screens/love_note_history_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'animated_couple_name.dart';
import 'love_lottie.dart';

/// The merged "Hôm nay của hai đứa" ritual card (Home v3, 2026-06-10): ONE
/// glass card carrying today's question AND the love-note exchange, replacing
/// the two stacked form-cards. Design principles applied:
///
/// 1. Question = tap-to-compose — a pill opens the answer bottom sheet.
/// 2. Blur-teaser — when the partner answered first, their answer shows
///    BLURRED with an unlock hint (the strongest answer motivator).
/// 3. Collapsing done-state — after a (stale) reveal the question block
///    shrinks to one line; a fresh reveal stays expanded and celebrates.
/// 4. Love note: an unread partner message shows its content IMMEDIATELY,
///    flagged with a "NEW" badge + rose outline that clear themselves a few
///    seconds later (seen-marker persisted per couple in Hive). Full
///    history is shared.
/// 5. One footer row links the journal + note history archives.
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

  // ── Love-note seen tracking (envelope) ────────────────────────────────────
  // Marker = updatedAt millis (or text hash when missing); stored per couple
  // in the existing `app_settings` Hive box. Until loaded we render the
  // plain-note state so read notes never flash an envelope.
  String? _seenMarker;
  bool _seenLoaded = false;

  /// Auto-clears the "NEW" flag shortly after an unread note is shown.
  Timer? _noteSeenTimer;

  String get _seenKey => 'love_note_seen_${widget.couple.id}';

  @override
  void initState() {
    super.initState();
    final daily = context.read<DailyQuestionProvider>();
    _confettiPlayed = daily.hasRevealed;
    _revealExpanded = !daily.hasRevealed;
    _loadSeenMarker();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _noteSeenTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSeenMarker() async {
    final box = await Hive.openBox<String>('app_settings');
    if (mounted) {
      setState(() {
        _seenMarker = box.get(_seenKey);
        _seenLoaded = true;
      });
    }
  }

  String _markerFor(LoveNote note) =>
      '${note.updatedAt?.millisecondsSinceEpoch ?? note.text.hashCode}';

  bool _isUnread(LoveNote note) =>
      _seenLoaded && _seenMarker != _markerFor(note);

  Future<void> _markSeen(LoveNote note) async {
    final marker = _markerFor(note);
    setState(() => _seenMarker = marker);
    final box = await Hive.openBox<String>('app_settings');
    await box.put(_seenKey, marker);
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

  String _relativeTime(DateTime? when, AppLocalizations l10n) {
    if (when == null) {
      return l10n.loveNoteJustNow;
    }
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) {
      return l10n.loveNoteJustNow;
    }
    if (diff.inMinutes < 60) {
      return l10n.loveNoteMinutesAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      return l10n.loveNoteHoursAgo(diff.inHours);
    }
    return l10n.loveNoteDaysAgo(diff.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final daily = context.watch<DailyQuestionProvider>();
    final love = context.watch<LoveNoteProvider>();
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
        // Solid white reading surface (gallery/settings style) — the design
        // system reserves glass for decorative blocks, not content-heavy cards.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._buildQuestionSection(l10n, daily, langCode, partnerName,
                    isWaiting),
                _divider(),
                ..._buildLoveNoteSection(l10n, love, partnerName, isWaiting),
                if (!isWaiting) ...[
                  _divider(),
                  _buildArchiveLinks(l10n),
                ],
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

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.textPrimary.withValues(alpha: 0.10),
      ),
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
        _composePill(
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
      _composePill(
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

  // ── Love note ──────────────────────────────────────────────────────────────

  List<Widget> _buildLoveNoteSection(
    AppLocalizations l10n,
    LoveNoteProvider love,
    String partnerName,
    bool isWaiting,
  ) {
    // Classic layout (user 2026-06-10): partner's note + "your note" line +
    // ONE compose button. Chat semantics live underneath: "Soạn tin nhắn"
    // opens an EMPTY sheet (a new message, not an edit); sending identical /
    // empty text keeps everything unchanged. History stays the shared log.
    final partnerNote = love.partnerNote;
    final hasNote = partnerNote != null && partnerNote.hasText;
    final myNote = love.myNote;
    final hasMyNote = myNote?.hasText == true;
    final isNew = hasNote && _isUnread(partnerNote);
    // The content shows right away (no envelope to tap since 2026-06-10);
    // the NEW badge clears itself after the note has been on screen a bit.
    if (isNew && _noteSeenTimer == null) {
      _noteSeenTimer = Timer(const Duration(seconds: 6), () {
        _noteSeenTimer = null;
        if (!mounted) {
          return;
        }
        final note = context.read<LoveNoteProvider>().partnerNote;
        if (note != null && note.hasText && _isUnread(note)) {
          AnalyticsService.instance.logLoveNoteEnvelopeOpened();
          _markSeen(note);
        }
      });
    }

    return [
      Row(
        children: [
          const Icon(LucideIcons.mails,
              color: AppColors.accentRose, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.loveNoteLabel,
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
      const SizedBox(height: 12),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: _buildNoteBody(
          l10n,
          partnerNote: partnerNote,
          isNew: isNew,
          partnerName: partnerName,
          isWaiting: isWaiting,
        ),
      ),
      if (hasMyNote && myNote != null) ...[
        const SizedBox(height: 10),
        _noteBlock(
          title:
              '${l10n.loveNoteYouLabel} · ${_relativeTime(myNote.updatedAt, l10n)}',
          text: myNote.text,
          mine: true,
        ),
      ],
      if (!isWaiting) ...[
        const SizedBox(height: 14),
        _composePill(
          label: l10n.loveNoteComposeCta,
          icon: LucideIcons.feather,
          onTap: _openLoveNoteSheet,
        ),
      ],
    ];
  }

  /// The note body cycles between: waiting text → empty state → the
  /// partner's note (flagged while NEW).
  Widget _buildNoteBody(
    AppLocalizations l10n, {
    required LoveNote? partnerNote,
    required bool isNew,
    required String partnerName,
    required bool isWaiting,
  }) {
    if (isWaiting) {
      return Text(
        l10n.loveNoteWaitingPartner,
        key: const ValueKey('note-waiting'),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      );
    }

    if (partnerNote == null || !partnerNote.hasText) {
      return Text(
        l10n.loveNoteEmptyFromPartner(partnerName),
        key: const ValueKey('note-empty'),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          height: 1.5,
        ),
      );
    }

    return KeyedSubtree(
      key: ValueKey('note-open-${_markerFor(partnerNote)}-$isNew'),
      child: _noteBlock(
        title: '$partnerName · ${_relativeTime(partnerNote.updatedAt, l10n)}',
        text: partnerNote.text,
        mine: false,
        isNew: isNew,
      ),
    );
  }

  /// Note block — the SAME two-tone language as the answer blocks above it
  /// (one card, one language): mine = surfaceLight + rose label, partner =
  /// lavender tint + lavender label.
  Widget _noteBlock({
    required String title,
    required String text,
    required bool mine,
    bool isNew = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mine
            ? AppColors.surfaceLight
            : AppColors.accentLavender.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        // Rose outline marks a just-arrived message (clears with the badge).
        border: isNew
            ? Border.all(
                color: AppColors.accentLove.withValues(alpha: 0.45),
                width: 1.2,
              )
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mine
                        ? AppColors.accentLoveDeep
                        : AppColors.accentLavenderDeep,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (isNew) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentLoveDeep,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.loveNoteNewBadge,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ],
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

  Future<void> _openLoveNoteSheet() async {
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    final currentText = context.read<LoveNoteProvider>().myNote?.text ?? '';

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // The field starts EMPTY (composing a new message, not editing); the
      // sheet only saves when the content actually differs from the current
      // note — identical/empty input keeps everything unchanged.
      builder: (_) => _LoveNoteSheet(
        currentText: currentText,
        partnerName: _partnerName(l10n),
        l10n: l10n,
      ),
    );

    if (saved != true || !mounted) {
      return;
    }
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.loveNoteSaved)),
    );
  }

  // ── Footer archive links ───────────────────────────────────────────────────

  Widget _buildArchiveLinks(AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _archiveLink(
            icon: LucideIcons.bookOpen,
            label: l10n.journalLinkShort,
            onTap: () => _push(const JournalScreen(), 'Journal'),
          ),
        ),
        Container(
          width: 1,
          height: 22,
          color: AppColors.textPrimary.withValues(alpha: 0.10),
        ),
        Expanded(
          child: _archiveLink(
            icon: LucideIcons.history,
            label: l10n.loveNoteHistoryLinkShort,
            onTap: () =>
                _push(const LoveNoteHistoryScreen(), 'LoveNoteHistory'),
          ),
        ),
      ],
    );
  }

  void _push(Widget screen, String routeName) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (_) => screen,
      ),
    );
  }

  Widget _archiveLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: AppColors.accentRose),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Shared bits ────────────────────────────────────────────────────────────

  /// Tap-to-compose pill: looks like a quiet input, opens a bottom sheet.
  /// [emphasized] = rose-tinted (the unlock CTA under the blur teaser).
  Widget _composePill({
    required String label,
    required VoidCallback onTap,
    IconData icon = LucideIcons.edit3,
    bool emphasized = false,
  }) {
    final fill = emphasized
        ? AppColors.accentLove.withValues(alpha: 0.10)
        : AppColors.surfaceLight;
    final border = AppColors.accentRose.withValues(alpha: emphasized ? 0.30 : 0.25);
    final textColor =
        emphasized ? AppColors.accentLoveDeep : AppColors.textSecondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.accentRose.withValues(alpha: 0.08),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Icon(icon, size: 17, color: AppColors.accentRose),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight:
                          emphasized ? FontWeight.w700 : FontWeight.w500,
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

/// Bottom sheet for composing a love-note message. The field starts EMPTY —
/// it composes a NEW message rather than editing the old one. Pops `true`
/// only when the note actually changed; identical or empty input pops `false`
/// and keeps the current note untouched (user rule 2026-06-10).
class _LoveNoteSheet extends StatefulWidget {
  const _LoveNoteSheet({
    required this.currentText,
    required this.partnerName,
    required this.l10n,
  });

  /// The user's current note, used for the keep-if-unchanged rule.
  final String currentText;
  final String partnerName;
  final AppLocalizations l10n;

  @override
  State<_LoveNoteSheet> createState() => _LoveNoteSheetState();
}

class _LoveNoteSheetState extends State<_LoveNoteSheet> {
  static const int _maxChars = 140;
  final TextEditingController _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final text = _controller.text.trim();
    // Keep-as-is rule: empty input or the exact same content as the current
    // note → close without touching anything.
    if (text.isEmpty || text == widget.currentText.trim()) {
      Navigator.of(context).pop(false);
      return;
    }
    setState(() => _saving = true);
    final navigator = Navigator.of(context);
    final saved = await context.read<LoveNoteProvider>().setMyNote(text);
    if (!mounted) {
      return;
    }
    navigator.pop(saved);
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
                  const Icon(LucideIcons.heart,
                      color: AppColors.accentRose, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.loveNoteSheetTitleTo(widget.partnerName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _controller,
                maxLength: _maxChars,
                maxLines: 4,
                minLines: 2,
                autofocus: true,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: l10n.loveNoteSheetHint,
                  counterText: l10n.loveNoteCharCount(
                    _controller.text.characters.length,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    // Rose, not the generic navy: this is a romantic SEND,
                    // matching the compose pill that opened the sheet.
                    backgroundColor: AppColors.accentRose,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor:
                        AppColors.accentRose.withValues(alpha: 0.35),
                    disabledForegroundColor:
                        AppColors.white.withValues(alpha: 0.8),
                  ),
                  onPressed: (_saving || _controller.text.trim().isEmpty)
                      ? null
                      : _save,
                  icon: _saving
                      ? const SizedBox.shrink()
                      : const Icon(LucideIcons.send, size: 18),
                  label: _saving
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
