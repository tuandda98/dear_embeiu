import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/love_note.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/love_note_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_app_bar.dart';

/// "Note journal" (feature love-note-history) — MESSENGER-STYLE chat redesign
/// (user 2026-06-11: "liền mạch, giống design của messenger"):
///
/// - One continuous conversation instead of uniform name+date cards: my notes
///   are right-aligned NAVY bubbles (white ink — navy is the app's primary-
///   action colour; the earlier red gradient clashed with the pink background
///   and echoed the destructive palette, review 2026-06-11), the partner's are
///   left-aligned white bubbles (dark ink) with a small initial avatar on the
///   last bubble of each burst — in a two-person chat the SIDE encodes the
///   author, so no per-message name row.
/// - Timestamps become ONE centered micro-caps separator per day (love notes
///   are sparse — a per-burst rule rendered a divider above nearly every
///   bubble and read like a log).
/// - Consecutive bubbles from the same author group tightly (3px) with the
///   in-between corners flattened; the list is chronological with the NEWEST
///   at the bottom (`reverse: true`, opens scrolled to the latest note).
///
/// Reads from [LoveNoteProvider.historyEntries] — the provider owns the
/// realtime window (newest 50) plus the accumulated older pages (pagination
/// D5); this screen arms the stream on open and releases it on close.
class LoveNoteHistoryScreen extends StatefulWidget {
  const LoveNoteHistoryScreen({super.key});

  @override
  State<LoveNoteHistoryScreen> createState() => _LoveNoteHistoryScreenState();
}

class _LoveNoteHistoryScreenState extends State<LoveNoteHistoryScreen> {
  late final LoveNoteProvider _provider;

  /// Messenger-style composer (2026-06-11): notes can be SENT from here, not
  /// just read — same [LoveNoteProvider.setMyNote] flow as the Home ritual
  /// card (updates the note + appends the archive), so the realtime history
  /// stream pops the new bubble in immediately.
  final TextEditingController _composer = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    // Keep the reference: context lookups aren't safe in dispose().
    _provider = context.read<LoveNoteProvider>();
    _provider.startHistory();
  }

  @override
  void dispose() {
    _composer.dispose();
    _provider.stopHistory();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _sending = true);
    var ok = false;
    try {
      ok = await _provider.setMyNote(text);
    } catch (_) {
      ok = false; // Offline / rules error — keep the draft, tell the user.
    }
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      _composer.clear();
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(content: Text(context.l10n.loveNoteSendFailed)),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final myUid = context.read<AuthProvider>().currentUser?.id ?? '';
    final provider = context.watch<LoveNoteProvider>();
    final entries = provider.historyEntries;
    // Partner's initial for the burst avatar (Messenger-style identity).
    final couple = context.read<CoupleProvider>().couple;
    final partnerName = couple == null
        ? ''
        : (myUid == couple.createdByUserId
                ? couple.person2Name
                : couple.person1Name)
            .trim();
    final partnerInitial =
        partnerName.isNotEmpty ? partnerName.characters.first.toUpperCase() : '♥';

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.secondaryGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Header vòng 5c (2026-06-11): the bar keeps only the back squircle —
        // the landing-style large header (EyebrowChip + pageTitle + subtitle)
        // lives in the body and scrolls with the content, like Settings.
        appBar: subScreenAppBar(context),
        // bottom SafeArea OFF: the composer paints its own white background
        // all the way down past the home indicator (Messenger does the same);
        // it pads its content by the bottom inset instead.
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: Builder(
                  builder: (context) {
                    if (provider.historyLoading && entries.isEmpty) {
                      return const _ChatSkeleton();
                    }
                    if (entries.isEmpty) {
                      // Empty state is centered (nothing scrolls), so the
                      // header is simply pinned above it.
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                            child: _HistoryHeader(),
                          ),
                          Expanded(child: _EmptyState(l10n: l10n)),
                        ],
                      );
                    }
                    return _ChatList(
                      entries: entries,
                      myUid: myUid,
                      partnerInitial: partnerInitial,
                      hasMore: provider.historyHasMore,
                      isLoadingMore: provider.historyLoadingMore,
                      onLoadMore: provider.loadMoreHistory,
                    );
                  },
                ),
              ),
              _buildComposer(l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Messenger-reference composer bar: white strip running past the home
  /// indicator, a borderless rounded input pill, and a send disc that lights
  /// navy (the outgoing-bubble colour) only when there's a draft.
  Widget _buildComposer(AppLocalizations l10n) {
    // Outside the bottom SafeArea on purpose — the white surface must reach
    // the physical bottom edge; only the CONTENT pads above the indicator.
    // (MediaQuery.padding.bottom collapses to 0 while the keyboard is up, so
    // this never double-pads on top of the keyboard inset.)
    final bottomInset = MediaQuery.of(context).padding.bottom;

    // All borders muted explicitly: the app-wide InputDecorationTheme draws a
    // rose focus outline (great on forms, noisy inside a chat bar — it read
    // as a validation error, user 2026-06-11).
    final noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide.none,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _composer,
              minLines: 1,
              maxLines: 4,
              // The love-note contract: text ≤ 140 (Firestore rules) — the
              // counter stays hidden like Messenger; the cap just holds.
              maxLength: 140,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.4,
              ),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                hintText: l10n.loveNoteSheetHint,
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: AppColors.surfaceLight,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                border: noBorder,
                enabledBorder: noBorder,
                focusedBorder: noBorder,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Send disc — listens to the draft: quiet ghost while empty, navy
          // (the outgoing-bubble colour) once there's something to send.
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _composer,
            builder: (context, value, _) {
              final canSend = value.text.trim().isNotEmpty && !_sending;
              return Semantics(
                label: l10n.loveNoteComposeCta,
                button: true,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: canSend || _sending
                        ? AppColors.textPrimary
                        : AppColors.surfaceLight,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      splashColor: AppColors.white.withValues(alpha: 0.15),
                      onTap: canSend ? _send : null,
                      child: Center(
                        child: _sending
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
                            : Icon(
                                LucideIcons.send,
                                size: 19,
                                color: canSend
                                    ? AppColors.white
                                    : AppColors.textTertiary,
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The conversation: provider entries arrive newest-first; we lay them out
/// chronologically and render through `reverse: true` so the screen opens at
/// the latest note and grows upward — standard chat behaviour.
class _ChatList extends StatelessWidget {
  const _ChatList({
    required this.entries,
    required this.myUid,
    required this.partnerInitial,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
  });

  final List<LoveNote> entries;
  final String myUid;
  final String partnerInitial;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final notes = entries.reversed.toList(); // chronological: oldest → newest

    // ONE separator per DAY (review 2026-06-11): love notes are sparse, so a
    // gap-based rule put a divider above nearly every bubble — log, not chat.
    final hasSeparator = List<bool>.filled(notes.length, false);
    DateTime? lastDay;
    for (var i = 0; i < notes.length; i++) {
      final when = notes[i].updatedAt;
      if (when != null) {
        final day = DateTime(when.year, when.month, when.day);
        hasSeparator[i] = lastDay == null || day != lastDay;
        lastDay = day;
      }
    }

    final items = <Widget>[const _HistoryHeader()];
    // "Show more" sits between the header and the OLDEST note (pagination D5)
    // — in a chat, older history loads from the top, like Messenger.
    if (hasMore) {
      items.add(_LoadMoreButton(isLoading: isLoadingMore, onTap: onLoadMore));
    }
    for (var i = 0; i < notes.length; i++) {
      final note = notes[i];
      final isMine = note.authorUserId == myUid;
      // Same-author bubbles with no separator between them read as one burst:
      // tight 3px spacing + flattened in-between corners.
      final firstInGroup = hasSeparator[i] ||
          i == 0 ||
          notes[i - 1].authorUserId != note.authorUserId;
      final lastInGroup = i == notes.length - 1 ||
          hasSeparator[i + 1] ||
          notes[i + 1].authorUserId != note.authorUserId;

      if (hasSeparator[i]) {
        items.add(_TimeDivider(when: note.updatedAt!));
      }
      items.add(Padding(
        padding: EdgeInsets.only(
          top: hasSeparator[i] ? 0 : (firstInGroup ? 10 : 3),
        ),
        child: _ChatBubble(
          text: note.text,
          isMine: isMine,
          firstInGroup: firstInGroup,
          lastInGroup: lastInGroup,
          partnerInitial: partnerInitial,
        ),
      ));
    }

    // reverse:true puts logical item 0 at the visual bottom — so we feed the
    // items back-to-front and the header (items[0]) ends up on top.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      itemCount: items.length,
      itemBuilder: (context, index) => items[items.length - 1 - index],
    );
  }
}

/// "Show more" pill — same visual language as the journal's load-more button
/// (outlined accentLove pill, w700 label, inline spinner while fetching); only
/// the chevron points UP because older notes reveal above, not below.
class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.isLoading, required this.onTap});

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: isLoading
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap();
                  },
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.accentLove, width: 1.4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.accentLove),
                      ),
                    )
                  else
                    const Icon(
                      LucideIcons.chevronUp,
                      size: 16,
                      color: AppColors.accentLove,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    l10n.journalLoadMore,
                    style: const TextStyle(
                      color: AppColors.accentLove,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
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

/// Landing-style page header (vòng 5c): chip + large title + subtitle —
/// same pattern (and 14/8/20 spacing) as Settings.
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EyebrowChip(label: l10n.loveNoteHistoryBadge, icon: LucideIcons.mail),
        const SizedBox(height: 14),
        Text(l10n.loveNoteHistoryTitle, style: AppTheme.pageTitleStyle()),
        const SizedBox(height: 8),
        Text(
          l10n.loveNoteHistoryHeaderSubtitle,
          style: AppTheme.pageSubtitleStyle(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Centered DAY separator (one per day, micro-caps): today shows just the
/// time, this year drops the year, older days carry the full date — all
/// locale-aware (D3). textSecondary w700: the old textTertiary w600 sank
/// into the gradient (review 2026-06-11).
class _TimeDivider extends StatelessWidget {
  const _TimeDivider({required this.when});

  final DateTime when;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final sameDay = when.year == now.year &&
        when.month == now.month &&
        when.day == now.day;
    final label = (sameDay
            ? DateFormat.Hm(locale).format(when)
            : when.year == now.year
                ? DateFormat.MMMd(locale).add_Hm().format(when)
                : DateFormat.yMMMd(locale).add_Hm().format(when))
        .toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMine,
    required this.firstInGroup,
    required this.lastInGroup,
    required this.partnerInitial,
  });

  final String text;
  final bool isMine;
  final bool firstInGroup;
  final bool lastInGroup;
  final String partnerInitial;

  @override
  Widget build(BuildContext context) {
    const full = Radius.circular(18);
    // 10 (not 6): the flatter corner made bursts read as a jagged staircase
    // (review 2026-06-11) — 10 still groups, without the saw-tooth edge.
    const flat = Radius.circular(10);
    // The sender-side corners flatten between grouped bubbles (Messenger's
    // burst look); the opposite side stays fully rounded.
    final radius = isMine
        ? BorderRadius.only(
            topLeft: full,
            bottomLeft: full,
            topRight: firstInGroup ? full : flat,
            bottomRight: lastInGroup ? full : flat,
          )
        : BorderRadius.only(
            topRight: full,
            bottomRight: full,
            topLeft: firstInGroup ? full : flat,
            bottomLeft: lastInGroup ? full : flat,
          );

    final bubble = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: isMine
          // NAVY, not the red gradient (review 2026-06-11): saturated red on
          // its own pink tint vibrates, echoes the app's destructive palette,
          // and white-on-love only hits ~3.2:1. Navy is the app's primary-
          // action colour (every main pill button) — "my action" — and gives
          // white ink ~15:1.
          ? BoxDecoration(
              color: AppColors.textPrimary,
              borderRadius: radius,
            )
          : BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
      child: Text(
        text,
        style: TextStyle(
          color: isMine ? AppColors.white : AppColors.textPrimary,
          fontSize: 15,
          height: 1.4,
        ),
      ),
    );

    if (isMine) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }
    // Partner side: a small initial avatar sits beside the LAST bubble of
    // each burst (Messenger identity); earlier bubbles keep an empty slot so
    // the whole burst stays left-aligned to the same edge.
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastInGroup)
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Text(
                partnerInitial,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            )
          else
            const SizedBox(width: 24),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

/// Content-shaped loading state: header + a few alternating bubbles so the
/// layout doesn't jump when the stream delivers.
class _ChatSkeleton extends StatelessWidget {
  const _ChatSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bubble(double width, {required bool mine}) {
      final shape = ShimmerSkeleton(width: width, height: 40, borderRadius: 18);
      return Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        // Partner rows reserve the 24+8 avatar slot, like the real layout.
        child: mine
            ? shape
            : Padding(
                padding: const EdgeInsets.only(left: 32),
                child: shape,
              ),
      );
    }

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: _HistoryHeader(),
        ),
        bubble(190, mine: false),
        const SizedBox(height: 3),
        bubble(140, mine: false),
        const SizedBox(height: 10),
        bubble(170, mine: true),
        const SizedBox(height: 10),
        bubble(210, mine: false),
        const SizedBox(height: 10),
        bubble(120, mine: true),
        const SizedBox(height: 3),
        bubble(180, mine: true),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cardSurface.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mailOpen,
                size: 30,
                color: AppColors.accentRose,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              // Chat invite, not "archive is empty" — the composer below can
              // start the conversation right here (2026-06-11).
              l10n.loveNoteStartChat,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
