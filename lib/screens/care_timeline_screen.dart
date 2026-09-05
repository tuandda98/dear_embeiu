import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/care_message.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../services/care_message_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';
import 'care_message_screen.dart';

/// Opens the "care timeline" — the permanent, day-grouped history of every care
/// note the couple exchanged (feature care-message).
///
/// Exported as a function (same shape as [openCareMessageScreen]) so every
/// entry point — Profile tile, "See all" on the composer, a care-note tap in
/// the notification center — pushes it identically, with one route name.
void openCareTimeline(BuildContext context, {String? focusMessageId}) {
  HapticFeedback.selectionClick();
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'CareTimeline'),
      builder: (_) => CareTimelineScreen(focusMessageId: focusMessageId),
    ),
  );
}

/// "Dòng thời gian quan tâm" — care notes newest-first, grouped by day.
///
/// Deliberately SEPARATE from the question journal (user 2026-09-05: care notes
/// get their own timeline, they are not folded into the daily-question days).
///
/// Paged with one-shot reads (30/page, infinite scroll) rather than a stream:
/// the history is append-only and can grow without bound, so a live listener on
/// the whole collection would be wasteful — pull-to-refresh covers "did a new
/// one arrive while I was reading".
class CareTimelineScreen extends StatefulWidget {
  const CareTimelineScreen({super.key, this.focusMessageId});

  /// Optional care-note id to deep-link to (a `care_message` tap in the
  /// notification center). The matching card is scrolled into view and briefly
  /// outlined. Ignored when null or when the note can't be found within the
  /// first few pages.
  final String? focusMessageId;

  @override
  State<CareTimelineScreen> createState() => _CareTimelineScreenState();
}

class _CareTimelineScreenState extends State<CareTimelineScreen> {
  static const int _pageSize = 30;

  /// How many EXTRA pages we're willing to pull while hunting for a deep-linked
  /// note. Beyond that the note is simply not focused (the list still works).
  static const int _maxFocusPages = 5;

  final CareMessageService _service = CareMessageService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _focusKey = GlobalKey();

  final List<CareMessage> _items = <CareMessage>[];
  CareMessagePage _lastPage = const CareMessagePage.empty();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  bool _highlightFocus = false;
  bool _focusHandled = false;

  String _coupleId = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _coupleId = context.read<CoupleProvider>().couple?.id ?? '';
      _loadFirstPage();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Prefetch while there's still a screenful left below.
    if (position.pixels >= position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadFirstPage() async {
    if (_coupleId.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    // fetchPage is itself fail-soft (empty page on a Firestore error), so this
    // catch only guards against something escaping it — but without it a single
    // unexpected throw would leave the screen spinning forever.
    CareMessagePage page;
    try {
      page = await _service.fetchPage(coupleId: _coupleId, limit: _pageSize);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(page.items);
      _lastPage = page;
      _isLoading = false;
      _hasError = false;
    });
    await _resolveFocus();
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isLoading || !_lastPage.hasMore) return;
    final cursor = _lastPage.lastDoc;
    if (cursor == null) return;
    setState(() => _isLoadingMore = true);
    final page = await _service.fetchPage(
      coupleId: _coupleId,
      limit: _pageSize,
      startAfter: cursor,
    );
    if (!mounted) return;
    setState(() {
      _items.addAll(page.items);
      _lastPage = page;
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    _focusHandled = true; // A manual refresh cancels any pending deep-link hunt.
    await _loadFirstPage();
  }

  /// Deep-link: pull extra pages (bounded) until the focused note is loaded,
  /// then scroll it into view and pulse a rose outline for ~1.5s.
  Future<void> _resolveFocus() async {
    final id = widget.focusMessageId;
    if (id == null || id.isEmpty || _focusHandled) return;
    _focusHandled = true;

    var pagesPulled = 0;
    while (!_items.any((m) => m.id == id) &&
        _lastPage.hasMore &&
        pagesPulled < _maxFocusPages) {
      pagesPulled++;
      final cursor = _lastPage.lastDoc;
      if (cursor == null) break;
      final page = await _service.fetchPage(
        coupleId: _coupleId,
        limit: _pageSize,
        startAfter: cursor,
      );
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _lastPage = page;
      });
    }
    if (!mounted || !_items.any((m) => m.id == id)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final ctx = _focusKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
        );
      }
      if (!mounted) return;
      setState(() => _highlightFocus = true);
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _highlightFocus = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: SubScreenHeader(
                  badge: l10n.careTimelineBadge,
                  badgeIcon: IconsaxPlusLinear.clock,
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  color: AppColors.accentLove,
                  child: _buildBody(l10n),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_isLoading) {
      return const _TimelineLoading();
    }
    if (_hasError) {
      return _TimelineMessage(
        icon: IconsaxPlusLinear.cloud_cross,
        title: l10n.careTimelineLoadError,
        body: null,
        ctaLabel: l10n.journalRetry,
        onCta: _loadFirstPage,
      );
    }
    if (_items.isEmpty) {
      return _TimelineMessage(
        icon: IconsaxPlusLinear.message_favorite,
        title: l10n.careTimelineEmptyTitle,
        body: l10n.careTimelineEmptyBody,
        ctaLabel: l10n.careTimelineEmptyCta,
        onCta: () => openCareMessageScreen(context),
      );
    }
    return _buildList(l10n);
  }

  Widget _buildList(AppLocalizations l10n) {
    final couple = context.watch<CoupleProvider>().couple;
    final myUid = context.watch<AuthProvider>().currentUser?.id ?? '';
    final locale = Localizations.localeOf(context).toString();
    final rows = _buildRows(l10n, locale);

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: rows.length + (_lastPage.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= rows.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 18),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.accentLove),
                ),
              ),
            ),
          );
        }
        final row = rows[index];
        if (row.dayLabel != null) {
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : 18, bottom: 10),
            child: Text(
              row.dayLabel!,
              style: const TextStyle(
                color: AppColors.accentLove,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          );
        }

        final message = row.message!;
        final isFocus =
            widget.focusMessageId != null && message.id == widget.focusMessageId;
        Widget card = _CareTimelineCard(
          message: message,
          myUid: myUid,
          couple: couple,
          locale: locale,
        );
        if (isFocus) {
          card = AnimatedContainer(
            key: _focusKey,
            duration: const Duration(milliseconds: 320),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.accentLove
                    .withValues(alpha: _highlightFocus ? 0.65 : 0.0),
                width: 1.8,
              ),
            ),
            child: card,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: card,
        );
      },
    );
  }

  /// Flattens the newest-first notes into [day header, note, note, …] rows.
  /// Grouping uses the VIEWER's local calendar day (same convention as mood) —
  /// two phones in different time zones may group a borderline note differently
  /// and that's fine.
  List<_TimelineRow> _buildRows(AppLocalizations l10n, String locale) {
    final rows = <_TimelineRow>[];
    String? currentKey;
    for (final message in _items) {
      final when = message.createdAt;
      final key = when == null ? '' : _dayKey(when);
      if (key != currentKey) {
        currentKey = key;
        rows.add(_TimelineRow.day(_dayLabel(when, l10n, locale)));
      }
      rows.add(_TimelineRow.message(message));
    }
    return rows;
  }

  static String _dayKey(DateTime when) =>
      '${when.year}-${when.month}-${when.day}';

  String _dayLabel(DateTime? when, AppLocalizations l10n, String locale) {
    if (when == null) {
      return l10n.notifGroupToday.toUpperCase();
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) {
      return l10n.notifGroupToday.toUpperCase();
    }
    if (diff == 1) {
      return l10n.careTimelineYesterday.toUpperCase();
    }
    return DateFormat.yMMMMd(locale).format(when).toUpperCase();
  }
}

/// Either a day header or a note — the flattened list the ListView walks.
class _TimelineRow {
  const _TimelineRow.day(String label)
      : dayLabel = label,
        message = null;
  const _TimelineRow.message(CareMessage this.message) : dayLabel = null;

  final String? dayLabel;
  final CareMessage? message;
}

/// One care note: sender avatar + name, bold title, the FULL body, and the
/// time it was sent.
class _CareTimelineCard extends StatelessWidget {
  const _CareTimelineCard({
    required this.message,
    required this.myUid,
    required this.couple,
    required this.locale,
  });

  final CareMessage message;
  final String myUid;
  final Couple? couple;
  final String locale;

  /// The partner's display name from the couple (the creator is person1).
  /// Falls back to the neutral "người ấy" label used everywhere else.
  String _partnerName(AppLocalizations l10n) {
    final c = couple;
    if (c == null) return l10n.careMessageFromPartner;
    final name = message.authorUserId == c.createdByUserId
        ? c.person1Name
        : c.person2Name;
    return name.trim().isNotEmpty ? name.trim() : l10n.careMessageFromPartner;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mine = message.isMine(myUid);
    final name = mine ? l10n.careMessageFromMe : _partnerName(l10n);
    final accent =
        mine ? AppColors.accentLoveDeep : AppColors.accentLavenderDeep;
    final when = message.createdAt;

    return ContentCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AuthorAvatar(name: name, accent: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                when == null ? '' : DateFormat.Hm(locale).format(when),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message.title,
            style: AppTheme.sectionTitleStyle().copyWith(fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            message.body,
            // ⚠️ Flutter gotcha: `ellipsis` without maxLines lays the text out
            // as ONE line and clips it — a care note must show whole.
            overflow: TextOverflow.visible,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

// ── Loading / empty / error ─────────────────────────────────────────────────

class _TimelineLoading extends StatelessWidget {
  const _TimelineLoading();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) =>
          const ShimmerSkeleton(height: 96, borderRadius: 22),
    );
  }
}

/// Shared centered state (empty / error) — scrollable so pull-to-refresh still
/// works when there is nothing to scroll.
class _TimelineMessage extends StatelessWidget {
  const _TimelineMessage({
    required this.icon,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.onCta,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String ctaLabel;
  final VoidCallback onCta;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.zero,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 38,
                        color: AppColors.accentLove,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTheme.displaySerif(
                        size: 20,
                        weight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (body != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        body!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          onCta();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          ctaLabel,
                          style: const TextStyle(
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
        ],
      ),
    );
  }
}
