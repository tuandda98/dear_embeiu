import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/couple_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/eyebrow_chip.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/shimmer_skeleton.dart';
import 'love_note_history_screen.dart';

/// The "Trò chuyện" tab (feature chat) — the couple's private realtime chat,
/// second tab of the Home bottom nav (IndexedStack child, NOT a pushed route).
///
/// Speaks the same messenger language as [LoveNoteHistoryScreen] (design rule
/// #1): navy mine-bubbles / white partner-bubbles with burst grouping, centered
/// micro-caps time dividers, borderless pill input + navy send disc. The
/// conversation widgets are deliberately a DISCIPLINED COPY of the history
/// screen's privates (extraction was skipped to leave the just-fixed history
/// untouched — debt logged in project/features/chat/dev.md): divider rule here
/// adds the ≥60-minute gap, bubbles add the pending treatment, the composer is
/// a floating card instead of a full-width strip.
///
/// Header: a single PINNED chip row (EyebrowChip + history icon →
/// [LoveNoteHistoryScreen]) above the list — chat is the sanctioned exception
/// to the large-header rule (user 2026-06-12): in a reversed list the big
/// title sat at the OLDEST end, buried after a few messages, so it was
/// dropped and the chip row alone names the screen.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.keyboardVisible,
    this.onRequestTab,
  });

  /// Whether the software keyboard is up. Passed in by HomeScreen — the Home
  /// Scaffold (resizeToAvoidBottomInset) strips `viewInsets.bottom` from the
  /// MediaQuery its body sees, so this tab can't read it directly.
  final bool keyboardVisible;

  /// Asks HomeScreen to switch the bottom-nav tab (waiting-partner CTA → the
  /// Profile tab where the invite code lives).
  final ValueChanged<int>? onRequestTab;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _composer = TextEditingController();
  bool _sending = false;

  /// Last [ChatProvider.sendRejections] value already surfaced — a growth
  /// means a queued message was REFUSED by the server (rules denied long
  /// after the optimistic echo, e.g. couple dissolved while offline) and the
  /// user must hear about it instead of the bubble silently vanishing.
  late ChatProvider _chat;
  late int _surfacedRejections;

  @override
  void initState() {
    super.initState();
    _chat = context.read<ChatProvider>();
    _surfacedRejections = _chat.sendRejections;
    _chat.addListener(_onChatChanged);
  }

  void _onChatChanged() {
    if (!mounted || _chat.sendRejections == _surfacedRejections) {
      return;
    }
    _surfacedRejections = _chat.sendRejections;
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(context.l10n.chatSendFailed)));
  }

  /// Message ids that must NOT play the new-message entrance: everything
  /// present when the conversation first loaded + everything already revealed.
  /// Only messages arriving while the tab is alive animate (design §5).
  final Set<String> _revealedIds = <String>{};
  bool _seededInitial = false;

  @override
  void dispose() {
    _chat.removeListener(_onChatChanged);
    _composer.dispose();
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
      ok = await context.read<ChatProvider>().send(text);
    } catch (_) {
      ok = false; // No couple / unexpected error — keep the draft.
    }
    if (!mounted) {
      return;
    }
    setState(() => _sending = false);
    if (ok) {
      HapticFeedback.mediumImpact();
      // Keep the keyboard up (D8): clear the draft, never unfocus.
      _composer.clear();
    } else {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(context.l10n.chatSendFailed)));
    }
  }

  void _openHistory() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: 'LoveNoteHistory'),
        builder: (_) => const LoveNoteHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<ChatProvider>();
    final couple = context.watch<CoupleProvider>().couple;
    final myUid = context.read<AuthProvider>().currentUser?.id ?? '';
    final waiting = couple?.isWaitingForPartner ?? true;
    final messages = provider.messages;

    // Seed the reveal set on the first delivered conversation so history never
    // animates — only messages that arrive afterwards do.
    if (!_seededInitial && !provider.isLoading) {
      for (final message in messages) {
        final id = message.id;
        if (id != null) {
          _revealedIds.add(id);
        }
      }
      _seededInitial = true;
    }

    // Partner's initial for the burst avatar (same resolution as history).
    final partnerName = couple == null
        ? ''
        : (myUid == couple.createdByUserId
                ? couple.person2Name
                : couple.person1Name)
            .trim();
    final partnerInitial = partnerName.isNotEmpty
        ? partnerName.characters.first.toUpperCase()
        : '♥';

    return Column(
      children: [
        // ── Tier 1: pinned chip row (the list never slides under it). ──────
        // Dynamic chip (user 2026-06-12): the couple's two names around the
        // pulsing heart instead of a static label — falls back to the static
        // badge until the couple (or a partner name) exists.
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
          child: Row(
            children: [
              Flexible(
                child: (couple != null &&
                        couple.person1Name.trim().isNotEmpty &&
                        couple.person2Name.trim().isNotEmpty)
                    ? EyebrowChip(
                        child: AnimatedCoupleName(
                          person1Name: couple.person1Name.toUpperCase(),
                          person2Name: couple.person2Name.toUpperCase(),
                          creatorUserId: couple.createdByUserId,
                          textStyle: AppTheme.pageEyebrowStyle(alpha: 0.70),
                          heartColor: AppColors.accentLoveDeep,
                          heartSize: 12,
                          spacing: 6,
                          runSpacing: 0,
                        ),
                      )
                    : EyebrowChip(
                        label: l10n.chatBadge,
                        icon: LucideIcons.messageCircle,
                      ),
              ),
              const Spacer(),
              const SizedBox(width: 8),
              HeaderIconButton(
                icon: LucideIcons.history,
                semanticsLabel: l10n.loveNoteHistoryTitle,
                onTap: _openHistory,
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (waiting) {
                return _WaitingPartnerState(
                  l10n: l10n,
                  onInviteTap: () => widget.onRequestTab?.call(3),
                );
              }
              if (provider.isLoading && messages.isEmpty) {
                return const _ChatSkeleton();
              }
              if (messages.isEmpty) {
                return _EmptyState(l10n: l10n);
              }
              return _MessageList(
                messages: messages,
                myUid: myUid,
                partnerInitial: partnerInitial,
                hasMore: provider.hasMore,
                isLoadingMore: provider.loadingMore,
                onLoadMore: provider.loadMore,
                revealedIds: _revealedIds,
              );
            },
          ),
        ),
        if (!waiting) _buildComposer(l10n),
      ],
    );
  }

  /// Floating-card composer (design §B4): white r24 card hovering ABOVE the
  /// floating nav while the keyboard is down, and hugging the keyboard once it
  /// opens (the nav hides itself; the Scaffold resize handles the inset). The
  /// 260ms padding animation matches the nav's own slide.
  Widget _buildComposer(AppLocalizations l10n) {
    // Keyboard open → root MediaQuery.padding.bottom collapses to 0, so this
    // never double-pads on top of the keyboard inset.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomClearance = widget.keyboardVisible
        ? 10.0
        : safeBottom + _navMargin + _navHeight + 10;

    // Borders muted explicitly: the app-wide rose focus outline reads like a
    // validation error inside a chat bar (same call as the history composer).
    final noBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide.none,
    );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomClearance),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 10),
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
                maxLines: 5,
                // The chat contract: text ≤ 1000 (Firestore rules, D2) — the
                // counter stays hidden; the cap just holds.
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  hintText: l10n.chatComposerHint,
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
            // Send disc — quiet ghost while empty, navy (the outgoing-bubble
            // colour, matching the history composer) once there's a draft.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _composer,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty && !_sending;
                return Semantics(
                  label: l10n.chatSendSemantics,
                  button: true,
                  // VoiceOver: announce the ghost state as disabled instead
                  // of a tappable button (tester bug #6).
                  enabled: canSend,
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
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
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
      ),
    );
  }

  // Mirrors HomeScreen's floating-nav geometry (design §B4) — the composer
  // must clear the nav by 10 while the keyboard is down.
  static const double _navHeight = 84;
  static const double _navMargin = 16;
}

/// The conversation: provider entries arrive newest-first; we lay them out
/// chronologically and render through `reverse: true` so the tab opens at the
/// latest message and grows upward — the title block is the logical FIRST item
/// (visual top), scrolling away while reading (design §B1.2).
class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.myUid,
    required this.partnerInitial,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.revealedIds,
  });

  final List<ChatMessage> messages;
  final String myUid;
  final String partnerInitial;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  /// Mutable set owned by the screen state: ids in here render statically;
  /// ids missing animate once and are then added (chat is append-only, so the
  /// set only ever grows).
  final Set<String> revealedIds;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final items = <ChatMessage>[...messages.reversed]; // oldest → newest

    // Divider rule for chat (denser than love notes): NEW DAY or a ≥60-minute
    // gap since the previous message (design §B2). Pending messages (no server
    // time yet) never start a divider.
    final hasSeparator = List<bool>.filled(items.length, false);
    DateTime? lastWhen;
    for (var i = 0; i < items.length; i++) {
      final when = items[i].createdAt;
      if (when != null) {
        hasSeparator[i] = lastWhen == null ||
            when.year != lastWhen.year ||
            when.month != lastWhen.month ||
            when.day != lastWhen.day ||
            when.difference(lastWhen).inMinutes >= 60;
        lastWhen = when;
      }
    }

    // No big title block in the conversation (user 2026-06-12: in a reversed
    // chat list it sits at the OLDEST end — buried after a few messages and
    // stranded next to "show more"; the pinned EyebrowChip row already names
    // the screen). Chat is the sanctioned exception to the large-header rule.
    final children = <Widget>[];
    // "Show more" sits between the title and the OLDEST message (D5) — older
    // history loads from the top, like Messenger.
    if (hasMore) {
      children
          .add(_LoadMoreButton(isLoading: isLoadingMore, onTap: onLoadMore));
    }
    for (var i = 0; i < items.length; i++) {
      final message = items[i];
      final isMine = message.authorUserId == myUid;
      final firstInGroup = hasSeparator[i] ||
          i == 0 ||
          items[i - 1].authorUserId != message.authorUserId;
      final lastInGroup = i == items.length - 1 ||
          hasSeparator[i + 1] ||
          items[i + 1].authorUserId != message.authorUserId;

      if (hasSeparator[i]) {
        children.add(_TimeDivider(when: message.createdAt!));
      }

      final id = message.id;
      final animate = !reduceMotion && id != null && !revealedIds.contains(id);
      if (id != null) {
        revealedIds.add(id);
      }

      children.add(Padding(
        padding: EdgeInsets.only(
          top: hasSeparator[i] ? 0 : (firstInGroup ? 10 : 3),
        ),
        child: _MessageEntrance(
          key: id == null ? null : ValueKey('chat-msg-$id'),
          animate: animate,
          child: _ChatBubble(
            text: message.text,
            isMine: isMine,
            isPending: message.isPending,
            firstInGroup: firstInGroup,
            lastInGroup: lastInGroup,
            partnerInitial: partnerInitial,
          ),
        ),
      ));
    }

    // reverse:true puts logical item 0 at the visual bottom — so we feed the
    // items back-to-front and the title block (children[0]) ends up on top.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      itemCount: children.length,
      itemBuilder: (context, index) => children[children.length - 1 - index],
    );
  }
}

/// One-shot new-message entrance: fade + 8px slide-up over 200ms, played only
/// when [animate] is true AT MOUNT (messages arriving live). Scroll-recycled
/// remounts get `animate: false` from the parent's revealed-ids set, so the
/// reveal can never replay. A plain controller (no flutter_animate) keeps the
/// element tree stable — see HomeScreen._entrance for the crash history.
class _MessageEntrance extends StatefulWidget {
  const _MessageEntrance({
    super.key,
    required this.animate,
    required this.child,
  });

  final bool animate;
  final Widget child;

  @override
  State<_MessageEntrance> createState() => _MessageEntranceState();
}

class _MessageEntranceState extends State<_MessageEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final CurvedAnimation _eased = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _eased.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isCompleted) {
      return widget.child;
    }
    return FadeTransition(
      opacity: _eased,
      child: AnimatedBuilder(
        animation: _eased,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, 8 * (1 - _eased.value)),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// "Show more" pill — same visual language as the history/journal load-more
/// (outlined accentLove, w700 label, inline spinner, chevron pointing UP).
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
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.accentLove,
                        ),
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

/// Centered time separator (micro-caps): today shows just the time, this year
/// drops the year, older days carry the full date — locale-aware (D3). Same
/// recipe as the history screen's divider.
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

/// Chat bubble (design §B3 — same chosen language as the history screen):
/// mine = solid navy, right; partner = solid white + initial avatar on the
/// last bubble of each burst, left. Pending mine-bubbles render at .65 opacity
/// with a small clock beside them until the server confirms (§4).
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMine,
    required this.isPending,
    required this.firstInGroup,
    required this.lastInGroup,
    required this.partnerInitial,
  });

  final String text;
  final bool isMine;
  final bool isPending;
  final bool firstInGroup;
  final bool lastInGroup;
  final String partnerInitial;

  @override
  Widget build(BuildContext context) {
    const full = Radius.circular(18);
    const flat = Radius.circular(10);
    // The sender-side corners flatten between grouped bubbles (burst look);
    // the opposite side stays fully rounded.
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
      // Pending (optimistic) treatment: .65 opacity + a small clock outside
      // the bubble's bottom-right corner; both clear when the server confirms.
      return Semantics(
        label: isPending ? context.l10n.chatSending : null,
        child: Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: isPending ? 0.65 : 1.0,
                  child: bubble,
                ),
              ),
              if (isPending) ...[
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Icon(
                    LucideIcons.clock3,
                    size: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // Partner side: a small initial avatar beside the LAST bubble of each
    // burst; earlier bubbles keep an empty slot so the burst stays aligned.
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (lastInGroup)
            ExcludeSemantics(
              child: Container(
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

/// Content-shaped loading state: title block + alternating shimmer bubbles so
/// the layout doesn't jump when the stream delivers (design §4).
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
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

/// Empty conversation (couple active, 0 messages): a quiet invite to type —
/// the composer below is live (design §4).
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
                LucideIcons.messageCircle,
                size: 30,
                color: AppColors.accentRose,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chatEmptyHint,
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

/// Waiting-partner state (couple not active yet): NO composer; the CTA jumps
/// to the Profile tab where the invite code lives (design §4).
class _WaitingPartnerState extends StatelessWidget {
  const _WaitingPartnerState({required this.l10n, required this.onInviteTap});

  final AppLocalizations l10n;
  final VoidCallback onInviteTap;

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
                LucideIcons.userPlus,
                size: 30,
                color: AppColors.accentRose,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chatWaitingPartnerTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.chatWaitingPartnerBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.textPrimary,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                splashColor: AppColors.white.withValues(alpha: 0.15),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onInviteTap();
                },
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.chatWaitingPartnerCta,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
