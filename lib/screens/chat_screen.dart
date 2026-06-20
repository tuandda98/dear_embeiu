import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
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

/// The "Trò chuyện" tab (feature chat) — the couple's private realtime chat,
/// second tab of the Home bottom nav (IndexedStack child, NOT a pushed route).
///
/// Speaks the same messenger language as the love-note journal (design rule
/// #1): navy mine-bubbles / white partner-bubbles with burst grouping, centered
/// micro-caps time dividers, borderless pill input + navy send disc. The
/// conversation widgets are deliberately a DISCIPLINED COPY of that screen's
/// privates (extraction was skipped to leave the just-fixed history
/// untouched — debt logged in project/features/chat/dev.md): divider rule here
/// adds the ≥60-minute gap, bubbles add the pending treatment, the composer is
/// a floating card instead of a full-width strip.
///
/// Header: a single PINNED chip row (just the EyebrowChip / couple-name) above
/// the list — chat is the sanctioned exception to the large-header rule (user
/// 2026-06-12): in a reversed list the big title sat at the OLDEST end, buried
/// after a few messages, so it was dropped and the chip row alone names the
/// screen. The old history icon (→ love-note journal) was removed 2026-06-14:
/// the chat tab now IS the couple's running conversation, so the separate
/// "past notes" entry was redundant.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.keyboardVisible,
    this.onRequestTab,
    this.onBack,
    this.hasBackground = false,
  });

  /// Whether the software keyboard is up. Passed in by HomeScreen — the Home
  /// Scaffold (resizeToAvoidBottomInset) strips `viewInsets.bottom` from the
  /// MediaQuery its body sees, so this tab can't read it directly.
  final bool keyboardVisible;

  /// Asks HomeScreen to switch the bottom-nav tab (waiting-partner CTA → the
  /// Profile tab where the invite code lives).
  final ValueChanged<int>? onRequestTab;

  /// Pops the chat back to the tab the user came from. When set, a back icon is
  /// shown in the header and the bottom nav is hidden by HomeScreen — chat is a
  /// full-screen drill-in (user 2026-06-17) rather than a peer tab.
  final VoidCallback? onBack;

  /// Whether HomeScreen is painting a custom photo backdrop behind this tab
  /// (feature chat-background, 2026-06-18). When true the back arrow rides a
  /// frosted disc so it stays legible over dark photo regions.
  final bool hasBackground;

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

    return Column(
      children: [
        // ── Tier 1: pinned chip row (the list never slides under it). ──────
        // Dynamic chip (user 2026-06-12): the couple's two names around the
        // pulsing heart instead of a static label — falls back to the static
        // badge until the couple (or a partner name) exists.
        Padding(
          // Tab-header geometry: gutter 16. Chat is a full-screen drill-in (not
          // a peer tab), so its header rides as high as the SafeArea allows
          // (top 0 — flush under the status bar/notch) — user 2026-06-18.
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          // Centered title chip (user 2026-06-17): the couple-name chip is CENTRED
          // in the row — back arrow pinned to the left gutter — same Stack recipe
          // as SubScreenHeader so the screen's title sits dead-centre instead of
          // hugging the back icon. Symmetric h-padding keeps a long name off the
          // back-arrow touch target.
          child: SizedBox(
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 44),
                  child:
                      (couple != null &&
                          couple.person1Name.trim().isNotEmpty &&
                          couple.person2Name.trim().isNotEmpty)
                      ? EyebrowChip(
                          // Natural slim height (user 2026-06-19, "nhẹ nhàng thanh
                          // lịch"): drop the forced-44 block so the chip rides at the
                          // same delicate pill height as every other tab's eyebrow —
                          // lighter, and finally CONSISTENT with Home/Gallery/Profile
                          // (those already pair a slim ~27 chip with a 44 control).
                          // The back disc centres beside it in the 44-tall Stack.
                          child: AnimatedCoupleName(
                            person1Name: couple.person1Name.toUpperCase(),
                            person2Name: couple.person2Name.toUpperCase(),
                            creatorUserId: couple.createdByUserId,
                            alignment: WrapAlignment.center,
                            // Header voice (refined 2026-06-19): a quiet tracked-caps
                            // TITLE — navy .85, 13/w700 ALL-CAPS tracked. A size and a
                            // weight lighter than the old chunky 15/w800 so it reads as
                            // a graceful eyebrow, yet caps-vs-lower + bold-vs-regular +
                            // tracked-vs-tight still set it apart from the sentence-case
                            // 15/w400 message bubbles below.
                            textStyle: AppTheme.pageEyebrowStyle(alpha: 0.85)
                                .copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                            heartColor: AppColors.accentLoveDeep,
                            heartSize: 11,
                            spacing: 6,
                            runSpacing: 0,
                          ),
                        )
                      : EyebrowChip(
                          label: l10n.chatBadge,
                          icon: IconsaxPlusLinear.messages,
                        ),
                ),
                // Back icon (user 2026-06-17): chat is a full-screen drill-in, so
                // it carries the app's standard back affordance at the left gutter.
                // -10 lands the 44 touch target's glyph on the gutter (like
                // SubScreenHeader). HomeScreen restores the tab the user came from.
                if (widget.onBack != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: const Offset(-10, 0),
                      child: HeaderIconButton(
                        icon: IconsaxPlusLinear.arrow_left,
                        onTap: widget.onBack!,
                        semanticsLabel: l10n.back,
                        // Over a photo backdrop the bare navy arrow vanishes on
                        // dark regions — give it the chip's frosted disc.
                        backed: widget.hasBackground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          // Tap anywhere on the conversation → drop the keyboard (user
          // 2026-06-20). opaque so taps on the empty padding around bubbles
          // register; the ListView's drag recogniser still wins scroll, and
          // inner InkWells (show-more) still win their own taps, so only true
          // empty-space taps reach here.
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
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
                // Status of the latest outgoing message (messages are newest-first,
                // so the first mine is the latest) — shown under its bubble.
                var latestMineStatus = ChatMessageStatus.none;
                for (final m in messages) {
                  if (m.authorUserId == myUid) {
                    latestMineStatus = provider.statusOf(m);
                    break;
                  }
                }
                return _MessageList(
                  messages: messages,
                  myUid: myUid,
                  latestMineStatus: latestMineStatus,
                  latestMineReadAt: provider.partnerReadAt,
                  hasMore: provider.hasMore,
                  isLoadingMore: provider.loadingMore,
                  onLoadMore: provider.loadMore,
                  revealedIds: _revealedIds,
                  hasBackground: widget.hasBackground,
                );
              },
            ),
          ),
        ),
        if (!waiting) _buildComposer(l10n),
      ],
    );
  }

  /// Floating-card composer (design §B4): white r24 card resting just above the
  /// safe-area while the keyboard is down (the bottom nav is hidden on this
  /// drill-in screen, so there is nothing to clear), and hugging the keyboard
  /// once it opens. The 260ms padding animation matches the keyboard slide.
  Widget _buildComposer(AppLocalizations l10n) {
    // Keyboard open → root MediaQuery.padding.bottom collapses to 0, so this
    // never double-pads on top of the keyboard inset.
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomClearance = widget.keyboardVisible ? 10.0 : safeBottom + 16;

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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : Icon(
                                  IconsaxPlusLinear.send_2,
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
}

/// The conversation: provider entries arrive newest-first; we lay them out
/// chronologically and render through `reverse: true` so the tab opens at the
/// latest message and grows upward — the title block is the logical FIRST item
/// (visual top), scrolling away while reading (design §B1.2).
class _MessageList extends StatefulWidget {
  const _MessageList({
    required this.messages,
    required this.myUid,
    required this.latestMineStatus,
    required this.latestMineReadAt,
    required this.hasMore,
    required this.isLoadingMore,
    required this.onLoadMore,
    required this.revealedIds,
    required this.hasBackground,
  });

  final List<ChatMessage> messages;
  final String myUid;

  /// Whether a custom photo backdrop is behind the list — the "naked" texts
  /// (time dividers + the delivery status) then ride a dark scrim pill so they
  /// stay legible over ANY photo region (which changes constantly).
  final bool hasBackground;

  /// Delivery status of the latest outgoing message — rendered under its
  /// bubble (đang gửi / đã gửi / đã nhận / đã đọc).
  final ChatMessageStatus latestMineStatus;

  /// When the partner last read up to — formatted as the "Đã xem · HH:mm" time
  /// under the latest outgoing bubble when its status is `read`.
  final DateTime? latestMineReadAt;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback onLoadMore;

  /// Mutable set owned by the screen state: ids in here render statically;
  /// ids missing animate once and are then added (chat is append-only, so the
  /// set only ever grows).
  final Set<String> revealedIds;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  // Infinite scroll (pagination D5b): reverse:true puts the NEWEST at offset 0
  // (bottom) and the OLDEST at maxScrollExtent (top), so scrolling up toward
  // older history drives pixels → maxExtent. Auto-load the next older page a
  // little before the very top so it streams in without a visible stop. Adding
  // older messages at the top of a reverse list keeps the read position put
  // (pixels unchanged), so there's no jump to compensate for. The "show more"
  // button stays as a manual fallback (e.g. a list too short to scroll).
  static const double _loadMoreThreshold = 400;

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!widget.hasMore || widget.isLoadingMore || !_controller.hasClients) {
      return;
    }
    final position = _controller.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      // loadMore() is itself re-entrancy guarded, so the few extra calls fired
      // while a page is in flight are harmless no-ops.
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = AppMotion.reduceMotion(context);
    final items = <ChatMessage>[...widget.messages.reversed]; // oldest → newest

    // Latest outgoing message (last mine in oldest→newest order) — the status
    // line (đang gửi / đã gửi / đã nhận / đã đọc) rides under just this bubble.
    var latestMineIndex = -1;
    for (var i = 0; i < items.length; i++) {
      if (items[i].authorUserId == widget.myUid) {
        latestMineIndex = i;
      }
    }

    // Divider rule for chat (denser than love notes): NEW DAY or a ≥60-minute
    // gap since the previous message (design §B2). Pending messages (no server
    // time yet) never start a divider.
    final hasSeparator = List<bool>.filled(items.length, false);
    DateTime? lastWhen;
    for (var i = 0; i < items.length; i++) {
      final when = items[i].createdAt;
      if (when != null) {
        hasSeparator[i] =
            lastWhen == null ||
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
    if (widget.hasMore) {
      children.add(
        _LoadMoreButton(
          isLoading: widget.isLoadingMore,
          onTap: widget.onLoadMore,
        ),
      );
    }
    for (var i = 0; i < items.length; i++) {
      final message = items[i];
      final isMine = message.authorUserId == widget.myUid;
      final firstInGroup =
          hasSeparator[i] ||
          i == 0 ||
          items[i - 1].authorUserId != message.authorUserId;
      final lastInGroup =
          i == items.length - 1 ||
          hasSeparator[i + 1] ||
          items[i + 1].authorUserId != message.authorUserId;

      if (hasSeparator[i]) {
        children.add(
          _TimeDivider(
            when: message.createdAt!,
            onBackground: widget.hasBackground,
          ),
        );
      }

      final id = message.id;
      final animate =
          !reduceMotion && id != null && !widget.revealedIds.contains(id);
      if (id != null) {
        widget.revealedIds.add(id);
      }

      children.add(
        Padding(
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
            ),
          ),
        ),
      );

      // Delivery status under the latest outgoing bubble only (iMessage style).
      if (i == latestMineIndex &&
          widget.latestMineStatus != ChatMessageStatus.none) {
        children.add(
          _StatusLabel(
            status: widget.latestMineStatus,
            readAt: widget.latestMineReadAt,
            onBackground: widget.hasBackground,
          ),
        );
      }
    }

    // reverse:true puts logical item 0 at the visual bottom — so we feed the
    // items back-to-front and the title block (children[0]) ends up on top.
    return ListView.builder(
      controller: _controller,
      reverse: true,
      // Drag the conversation → keyboard slides down too (Messenger/iMessage
      // idiom), complementing the tap-to-dismiss on the list area.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      IconsaxPlusLinear.arrow_up_1,
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
  const _TimeDivider({required this.when, this.onBackground = false});

  final DateTime when;

  /// On a photo backdrop the bare navy date vanishes over light regions — the
  /// label then rides a dark scrim pill + white ink so it reads on ANY photo.
  final bool onBackground;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final sameDay =
        when.year == now.year && when.month == now.month && when.day == now.day;
    final label =
        (sameDay
                ? DateFormat.Hm(locale).format(when)
                : when.year == now.year
                ? DateFormat.MMMd(locale).add_Hm().format(when)
                : DateFormat.yMMMd(locale).add_Hm().format(when))
            .toUpperCase();

    final text = Text(
      label,
      style: TextStyle(
        color: onBackground ? AppColors.white : AppColors.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Center(
        child: onBackground
            ? Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.38),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: text,
              )
            : text,
      ),
    );
  }
}

/// Chat bubble (design §B3 — same chosen language as the history screen):
/// mine = solid navy, right; partner = solid white, flush-left (no avatar —
/// 1-1 chat). Pending mine-bubbles render at .65 opacity with a small clock
/// beside them until the server confirms (§4).
class _ChatBubble extends StatelessWidget {
  const _ChatBubble({
    required this.text,
    required this.isMine,
    required this.isPending,
    required this.firstInGroup,
    required this.lastInGroup,
  });

  final String text;
  final bool isMine;
  final bool isPending;
  final bool firstInGroup;
  final bool lastInGroup;

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
          ? BoxDecoration(color: AppColors.textPrimary, borderRadius: radius)
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
                    IconsaxPlusLinear.clock,
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

    // Partner side: bubble flush-left, NO per-message avatar (dropped
    // 2026-06-18, user). This is a 1-1 couple chat, so the side + bubble colour
    // already name the sender — a per-bubble avatar is the group-chat idiom and
    // here it's just a redundant dot (iMessage/Zalo 1-1 convention).
    return Align(alignment: Alignment.centerLeft, child: bubble);
  }
}

/// Delivery-status line under the latest outgoing bubble (feature chat-status,
/// 2026-06-18): đang gửi → đã gửi → đã nhận → đã xem. iMessage-minimal (user
/// 2026-06-19): a small right-aligned TEXT label (no icon), and the read state
/// shows WHEN the partner saw it — "Đã xem · 23:30".
class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.status,
    required this.readAt,
    this.onBackground = false,
  });

  final ChatMessageStatus status;

  /// Partner's read time — appended to the read label as "· HH:mm".
  final DateTime? readAt;

  /// On a photo backdrop the grey text is lifted to white + a soft shadow so it
  /// stays legible over ANY photo region (no pill — minimal).
  final bool onBackground;

  @override
  Widget build(BuildContext context) {
    if (status == ChatMessageStatus.none) {
      return const SizedBox.shrink();
    }
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();

    var label = switch (status) {
      ChatMessageStatus.sending => l10n.chatSending,
      ChatMessageStatus.sent => l10n.chatStatusSent,
      ChatMessageStatus.delivered => l10n.chatStatusDelivered,
      ChatMessageStatus.read => l10n.chatStatusRead,
      ChatMessageStatus.none => '',
    };
    // "Đã xem · 23:30" — append the read time when we know it.
    if (status == ChatMessageStatus.read && readAt != null) {
      label = '$label · ${DateFormat.Hm(locale).format(readAt!)}';
    }
    if (label.isEmpty) {
      return const SizedBox.shrink();
    }

    // Grey text on the gradient; white text + soft shadow over a photo. "Đã xem"
    // sits a touch darker/stronger than the in-transit states.
    final baseColor = status == ChatMessageStatus.read
        ? AppColors.textSecondary
        : AppColors.textTertiary;
    final color = onBackground ? AppColors.white : baseColor;
    final shadows = onBackground
        ? <Shadow>[
            Shadow(color: Colors.black.withValues(alpha: 0.55), blurRadius: 3),
          ]
        : null;

    return Padding(
      padding: const EdgeInsets.only(top: 3, right: 6, bottom: 2),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
            color: color,
            shadows: shadows,
          ),
        ),
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
        // Both sides flush to their edge — partner bubbles no longer reserve an
        // avatar slot (avatar dropped 2026-06-18).
        child: shape,
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
                IconsaxPlusLinear.messages,
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
                IconsaxPlusLinear.user_add,
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
