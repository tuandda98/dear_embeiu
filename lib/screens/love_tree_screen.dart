import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/streak_provider.dart';
import '../services/love_tree_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/icon_badge.dart';
import '../widgets/ink_tile.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';

/// Love Tree (feature love-tree, 2026-06-14) — a pushed sub-screen reached by
/// tapping the [StreakChip]. A single tree, dressed 100% in [CustomPaint] (no
/// art assets), whose flowers ARE the couple's milestones (days / longest
/// streak / photos). Walking in while a new milestone is crossed plays a bloom
/// animation + banner, then stamps the per-couple "seen" marker so it only
/// celebrates once.
///
/// Data is read live from three existing providers (Couple/Streak/Photo); all
/// milestone math + the Hive marker live in [LoveTreeService] so this screen and
/// the chip's "unseen" badge agree exactly.
class LoveTreeScreen extends StatefulWidget {
  const LoveTreeScreen({super.key});

  @override
  State<LoveTreeScreen> createState() => _LoveTreeScreenState();
}

class _LoveTreeScreenState extends State<LoveTreeScreen> {
  /// The flower count the user last saw on this screen (read once at entry).
  int _lastSeen = 0;

  /// Whether we've already committed the seen marker this visit (so a rebuild
  /// from a late provider update doesn't re-arm the bloom).
  bool _seenCommitted = false;

  /// Whether the one-shot sparkle for this visit's new blooms already fired.
  bool _bloomCelebrated = false;

  /// Captured at entry so the bloom set (`[_seenAtEntry, flowerCount)`) is
  /// stable even as `_lastSeen` is updated post-frame.
  int _seenAtEntry = 0;

  String? _coupleId;

  late final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 700));

  @override
  void initState() {
    super.initState();
    final couple = context.read<CoupleProvider>().couple;
    _coupleId = couple?.id;
    if (_coupleId != null) {
      _lastSeen = LoveTreeService.readLastSeen(_coupleId!);
      _seenAtEntry = _lastSeen;
    }
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  /// Commits `lastSeen = flowers` once the bloom has been shown (post-frame),
  /// so reopening the screen won't animate again.
  void _commitSeen(int flowers) {
    if (_seenCommitted || _coupleId == null) {
      return;
    }
    _seenCommitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LoveTreeService.writeLastSeen(_coupleId!, flowers);
      if (mounted) {
        setState(() => _lastSeen = flowers);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final couple = context.watch<CoupleProvider>().couple;
    final streak = context.watch<StreakProvider>();
    final photo = context.watch<PhotoProvider>();

    final reduceMotion = AppMotion.reduceMotion(context);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: SubScreenHeader(
                  badge: l10n.loveTreeBadge,
                  badgeIcon: IconsaxPlusLinear.magic_star,
                ),
              ),
              Expanded(
                child: _buildBody(
                  context,
                  l10n,
                  couple: couple,
                  streak: streak,
                  photo: photo,
                  reduceMotion: reduceMotion,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n, {
    required Couple? couple,
    required StreakProvider streak,
    required PhotoProvider photo,
    required bool reduceMotion,
  }) {
    // No-couple / waiting → no garden, just the seed + an invite message.
    if (couple == null) {
      return _StateMessage(
        title: l10n.loveTreeStage0,
        body: l10n.loveTreeNoCoupleBody,
        reduceMotion: reduceMotion,
      );
    }
    if (couple.isWaitingForPartner) {
      return _StateMessage(
        title: l10n.loveTreeWaitingTitle,
        body: l10n.loveTreeWaitingBody,
        reduceMotion: reduceMotion,
        ctaLabel: l10n.loveTreeWaitingCta,
        onCta: () => Navigator.of(context).maybePop(),
      );
    }

    // Loading the streak window for the first time → skeleton (avoid jumping
    // the flower count from 0 up to the real value).
    final streakLoading =
        streak.isLoading && streak.state == StreakState.hidden;
    if (streakLoading) {
      return const _LoadingTree();
    }

    // Fail-soft: a failed source contributes 0 milestones, never blocks.
    final days = LoveTreeService.daysTogether(couple.anniversaryDate);
    final longestStreak = streak.hasError ? 0 : streak.longestStreak;
    final photoCount = photo.photoCount;

    final milestones = LoveTreeService.buildMilestones(
      days: days,
      longestStreak: longestStreak,
      photoCount: photoCount,
    );
    final reached = milestones.where((m) => m.reached).toList();
    final flowerCount = reached.length;
    final stage = LoveTreeService.stageForFlowers(flowerCount);

    final newCount =
        _coupleId == null ? 0 : (flowerCount - _seenAtEntry).clamp(0, flowerCount);
    final hasNewBlooms = newCount > 0;

    // Sparkle for the freshly bloomed flowers — fired ONCE per visit (a late
    // provider update mustn't re-trigger it) and never under reduce-motion.
    if (hasNewBlooms && !reduceMotion && !_bloomCelebrated) {
      _bloomCelebrated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _confetti.play();
        }
      });
    }

    // Stamp the seen marker after this frame (lets the bloom animate first).
    // Done for both the "new blooms" and the "nothing new" cases so the marker
    // stays in sync (e.g. the very first open at 0 flowers).
    _commitSeen(flowerCount);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. The tree hero.
          _TreeHero(
            stage: stage,
            reached: reached,
            newFromIndexInReached: flowerCount - newCount,
            reduceMotion: reduceMotion,
            confetti: _confetti,
          ),
          const SizedBox(height: 16),

          // 2. Stage title + flower count.
          Text(
            _stageTitle(l10n, stage),
            textAlign: TextAlign.center,
            style: AppTheme.sectionTitleStyle().copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            _stageSubtitle(l10n, stage, flowerCount),
            textAlign: TextAlign.center,
            style: AppTheme.pageSubtitleStyle(shadowed: false),
          ),

          // 3. Bloom banner (only when there are new flowers).
          if (hasNewBlooms) ...[
            const SizedBox(height: 16),
            _BloomBanner(count: newCount, reduceMotion: reduceMotion),
          ],

          const SizedBox(height: 20),

          // 4. "Grow it together".
          EntranceReveal(order: 1, child: _NurtureCard(l10n: l10n)),
          const SizedBox(height: 16),

          // 5. Milestones.
          EntranceReveal(
            order: 2,
            child: _MilestonesCard(
              l10n: l10n,
              milestones: milestones,
              days: days,
              longestStreak: longestStreak,
              photoCount: photoCount,
            ),
          ),
        ],
      ),
    );
  }

  String _stageTitle(AppLocalizations l10n, LoveTreeStage stage) {
    switch (stage) {
      case LoveTreeStage.seed:
        return l10n.loveTreeStage0;
      case LoveTreeStage.sprout:
        return l10n.loveTreeStage1;
      case LoveTreeStage.young:
        return l10n.loveTreeStage2;
      case LoveTreeStage.green:
        return l10n.loveTreeStage3;
      case LoveTreeStage.bloom:
        return l10n.loveTreeStage4;
    }
  }

  String _stageSubtitle(
      AppLocalizations l10n, LoveTreeStage stage, int flowerCount) {
    if (flowerCount == 0) {
      return l10n.loveTreeSeedSubtitle;
    }
    if (stage == LoveTreeStage.bloom) {
      return l10n.loveTreeBloomSubtitle;
    }
    return l10n.loveTreeFlowerCount(flowerCount);
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Tree hero (painter background + flower widget overlay)
// ───────────────────────────────────────────────────────────────────────────

class _TreeHero extends StatelessWidget {
  const _TreeHero({
    required this.stage,
    required this.reached,
    required this.newFromIndexInReached,
    required this.reduceMotion,
    required this.confetti,
  });

  final LoveTreeStage stage;

  /// Reached milestones in stable order (== the flowers, oldest first).
  final List<LoveTreeMilestone> reached;

  /// Index within [reached] from which flowers are "new" this visit (bloom).
  final int newFromIndexInReached;

  final bool reduceMotion;
  final ConfettiController confetti;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    // Tree area = ~52% of usable height, clamped (design §1/§8).
    final usable = media.size.height - media.padding.vertical;
    final treeHeight = (usable * 0.52).clamp(360.0, 460.0);

    return SizedBox(
      height: treeHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final positions = _bloomPositions(size, reached.length);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The tree itself (trunk / canopy / leaves / mound / bokeh).
              Positioned.fill(
                child: CustomPaint(
                  painter: LoveTreePainter(stage: stage),
                ),
              ),

              // Flowers — drawn bottom-up so upper flowers overlap lower ones.
              // Keyed by milestone identity so a flower's State is never
              // recycled as a different flower when the list grows mid-visit.
              for (int i = 0; i < reached.length; i++)
                Positioned(
                  key: ValueKey('${reached[i].kind}-${reached[i].value}'),
                  left: positions[i].dx - _flowerRadius(i, reached.length),
                  top: positions[i].dy - _flowerRadius(i, reached.length),
                  child: _LoveFlower(
                    kind: reached[i].kind,
                    diameter: _flowerDiameter(i, reached.length),
                    isNew: i >= newFromIndexInReached,
                    // Cap the visible stagger at 6 new flowers (design §4).
                    bloomOrder: (i - newFromIndexInReached).clamp(0, 6),
                    reduceMotion: reduceMotion,
                  ),
                ),

              // Sparkle for the new flowers, emitted from the canopy centre.
              Align(
                alignment: const Alignment(0, -0.35),
                child: ConfettiWidget(
                  confettiController: confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 10,
                  maxBlastForce: 12,
                  minBlastForce: 5,
                  emissionFrequency: 0.0,
                  gravity: 0.2,
                  shouldLoop: false,
                  colors: const [
                    AppColors.accentRose,
                    AppColors.accentLavender,
                    AppColors.white,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Base flower diameter ≈34px; small flowers near the rim scale to 0.82.
  double _flowerDiameter(int index, int count) {
    const base = 34.0;
    // Outer-ring flowers (later half) shrink slightly for a layered canopy.
    final outer = count > 1 && index >= count * 0.6;
    return outer ? base * 0.82 : base;
  }

  double _flowerRadius(int index, int count) =>
      _flowerDiameter(index, count) / 2;

  /// Deterministic phyllotaxis layout (design §3.3): golden-angle spiral +
  /// sqrt radius + a fixed per-index jitter, anchored to the ACTUAL stage canopy
  /// (so flowers always land on the leaves, not floating). No runtime
  /// randomness → flowers never shuffle between builds.
  List<Offset> _bloomPositions(Size size, int count) {
    if (count == 0) {
      return const [];
    }
    final (center, canopyR) = LoveTreePainter.canopyGeometry(stage, size);
    // Spread flowers across ~78% of the canopy radius so they stay inside the
    // leaves with a little margin.
    final r = canopyR * 0.78;
    const capacity = 14;
    const golden = 137.5 * math.pi / 180.0;

    final out = <Offset>[];
    for (int i = 0; i < count; i++) {
      final angle = i * golden;
      final radius = r * math.sqrt((i + 0.5) / capacity);
      final jx = (_hash(i) % 7) - 3; // -3..+3 (fixed per index)
      final jy = (_hash(i * 31 + 7) % 7) - 3;
      final x = center.dx + radius * math.cos(angle) + jx;
      // Flatten vertically (0.7) so flowers fan across the wide cloud canopy.
      final y = center.dy + radius * math.sin(angle) * 0.7 + jy;
      out.add(Offset(x, y));
    }
    return out;
  }

  int _hash(int i) {
    // Knuth multiplicative hash, kept positive — stable per index.
    var h = (i * 2654435761) & 0x7fffffff;
    h = (h >> 13) ^ h;
    return h & 0x7fffffff;
  }
}

/// Loading placeholder: a grey static tree silhouette + two shimmer pills.
class _LoadingTree extends StatelessWidget {
  const _LoadingTree();

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final usable = media.size.height - media.padding.vertical;
    final treeHeight = (usable * 0.52).clamp(360.0, 460.0);
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        children: [
          SizedBox(
            height: treeHeight,
            child: CustomPaint(
              size: Size.infinite,
              painter: LoveTreePainter(stage: LoveTreeStage.green, skeleton: true),
            ),
          ),
          const SizedBox(height: 16),
          const ShimmerSkeleton(width: 160, height: 24, borderRadius: 999),
          const SizedBox(height: 8),
          const ShimmerSkeleton(width: 120, height: 16, borderRadius: 999),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Bloom banner
// ───────────────────────────────────────────────────────────────────────────

class _BloomBanner extends StatelessWidget {
  const _BloomBanner({required this.count, required this.reduceMotion});

  final int count;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = count == 1
        ? l10n.loveTreeNewBloomBannerOne
        : l10n.loveTreeNewBloomBanner(count);

    final banner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentRose.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(IconsaxPlusLinear.magic_star, size: 16, color: AppColors.accentLoveDeep),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (reduceMotion) {
      return banner;
    }
    return EntranceReveal(order: 0, child: banner);
  }
}

// ───────────────────────────────────────────────────────────────────────────
// "Grow it together"
// ───────────────────────────────────────────────────────────────────────────

class _NurtureCard extends StatelessWidget {
  const _NurtureCard({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(IconsaxPlusLinear.tree, size: 18, color: AppColors.accentRose),
              const SizedBox(width: 8),
              Text(
                l10n.loveTreeNurtureTitle,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Each tile pops the tree and routes Home to the matching action
          // (user 2026-06-17): keep streak → today's question, add a memory →
          // the Gallery add-photo composer, chat → the Chat tab.
          _NurtureTile(
            icon: IconsaxPlusLinear.flash,
            tint: AppColors.accentCoral,
            title: l10n.loveTreeNurtureStreakTitle,
            body: l10n.loveTreeNurtureStreakBody,
            onTap: () => _goToDailyQuestion(context),
          ),
          const SizedBox(height: 10),
          _NurtureTile(
            icon: IconsaxPlusLinear.gallery,
            tint: AppColors.accentLavender,
            title: l10n.loveTreeNurturePhotoTitle,
            body: l10n.loveTreeNurturePhotoBody,
            onTap: () => _goToAddMemory(context),
          ),
          const SizedBox(height: 10),
          _NurtureTile(
            icon: IconsaxPlusLinear.messages,
            tint: AppColors.accentRose,
            title: l10n.loveTreeNurtureTalkTitle,
            body: l10n.loveTreeNurtureTalkBody,
            onTap: () => _goToChat(context),
          ),
        ],
      ),
    );
  }

  /// The Love Tree is a route pushed over Home, which owns the tabs + the
  /// daily-question card and listens to [NotificationTapRouter]. So each
  /// shortcut signals the destination through the router, then pops back to let
  /// Home apply it — the same bridge notification deep-links use.

  /// Keep-streak → Home tab, daily-question card scrolled into view.
  void _goToDailyQuestion(BuildContext context) {
    NotificationTapRouter.pendingHomeTab.value = 0;
    NotificationTapRouter.pendingHomeFocus.value = 'daily_question';
    Navigator.of(context).maybePop();
  }

  /// Add-a-memory → Gallery tab with its add-photo composer opened.
  void _goToAddMemory(BuildContext context) {
    NotificationTapRouter.pendingHomeTab.value = 2;
    NotificationTapRouter.pendingCompose.value = true;
    Navigator.of(context).maybePop();
  }

  /// Chat-today → Chat tab.
  void _goToChat(BuildContext context) {
    NotificationTapRouter.pendingHomeTab.value = 1;
    Navigator.of(context).maybePop();
  }
}

class _NurtureTile extends StatelessWidget {
  const _NurtureTile({
    required this.icon,
    required this.tint,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final IconData icon;
  final Color tint;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkTile(
      borderRadius: 22,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            IconBadge(icon, tint: tint),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(IconsaxPlusLinear.arrow_right_3,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Milestones list
// ───────────────────────────────────────────────────────────────────────────

class _MilestonesCard extends StatelessWidget {
  const _MilestonesCard({
    required this.l10n,
    required this.milestones,
    required this.days,
    required this.longestStreak,
    required this.photoCount,
  });

  final AppLocalizations l10n;
  final List<LoveTreeMilestone> milestones;
  final int days;
  final int longestStreak;
  final int photoCount;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    final reached = milestones.where((m) => m.reached).toList();
    for (final m in reached) {
      rows.add(_MilestoneRow(label: _label(m), kind: m.kind, reached: true));
    }

    // One "next" row per kind (the nearest unreached milestone of each).
    for (final kind in FlowerKind.values) {
      final next = milestones
          .where((m) => m.kind == kind && !m.reached)
          .fold<LoveTreeMilestone?>(null, (a, b) => a ?? b);
      if (next != null) {
        rows.add(_MilestoneRow(
          label: _label(next),
          kind: kind,
          reached: false,
          remaining: _remaining(next),
        ));
      }
    }

    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(IconsaxPlusLinear.flag, size: 18, color: AppColors.accentRose),
              const SizedBox(width: 8),
              Text(
                l10n.loveTreeMilestonesTitle,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Container(
                margin: const EdgeInsets.only(left: 56),
                height: 1,
                color: AppColors.textTertiary.withValues(alpha: 0.12),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _label(LoveTreeMilestone m) {
    switch (m.kind) {
      case FlowerKind.days:
        return l10n.loveTreeMilestoneDays(m.value);
      case FlowerKind.streak:
        return l10n.loveTreeMilestoneStreak(m.value);
      case FlowerKind.photos:
        return l10n.loveTreeMilestonePhotos(m.value);
    }
  }

  String _remaining(LoveTreeMilestone m) {
    switch (m.kind) {
      case FlowerKind.days:
        return l10n.loveTreeMilestoneDaysLeft((m.value - days).clamp(1, m.value));
      case FlowerKind.streak:
        return l10n
            .loveTreeMilestoneStreakLeft((m.value - longestStreak).clamp(1, m.value));
      case FlowerKind.photos:
        return l10n
            .loveTreeMilestonePhotosLeft((m.value - photoCount).clamp(1, m.value));
    }
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.label,
    required this.kind,
    required this.reached,
    this.remaining,
  });

  final String label;
  final FlowerKind kind;
  final bool reached;
  final String? remaining;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final discColor = LoveTreeService.nucleusColor(kind);
    final icon = LoveTreeService.nucleusIcon(kind);

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          // Mini nucleus disc (16px) — filled when reached, outlined when next.
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: reached ? discColor : Colors.transparent,
              border: reached
                  ? null
                  : Border.all(color: AppColors.textTertiary, width: 1.4),
            ),
            child: Icon(
              icon,
              size: 10,
              color: reached ? AppColors.white : AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: reached ? AppColors.textPrimary : AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (reached)
            _BloomedChip(l10n: l10n)
          else
            Text(
              remaining ?? '',
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );

    return Opacity(opacity: reached ? 1.0 : 0.65, child: row);
  }
}

class _BloomedChip extends StatelessWidget {
  const _BloomedChip({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_rounded, size: 12, color: AppColors.success),
          const SizedBox(width: 4),
          Text(
            l10n.loveTreeMilestoneBloomed,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// No-couple / waiting state
// ───────────────────────────────────────────────────────────────────────────

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.title,
    required this.body,
    required this.reduceMotion,
    this.ctaLabel,
    this.onCta,
  });

  final String title;
  final String body;
  final bool reduceMotion;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final usable = media.size.height - media.padding.vertical;
    final treeHeight = (usable * 0.40).clamp(280.0, 380.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          SizedBox(
            height: treeHeight,
            child: CustomPaint(
              size: Size.infinite,
              painter: LoveTreePainter(stage: LoveTreeStage.seed),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                AppTheme.sectionTitleStyle().copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AppTheme.pageSubtitleStyle(shadowed: false),
          ),
          if (ctaLabel != null && onCta != null) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentRose,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  onCta!();
                },
                child: Text(
                  ctaLabel!,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Flower widget (petals CustomPaint + Lucide-icon nucleus disc)
// ───────────────────────────────────────────────────────────────────────────

class _LoveFlower extends StatefulWidget {
  const _LoveFlower({
    required this.kind,
    required this.diameter,
    required this.isNew,
    required this.bloomOrder,
    required this.reduceMotion,
  });

  final FlowerKind kind;
  final double diameter;
  final bool isNew;

  /// Stagger slot among the new flowers (0-based), for the cascading bloom.
  final int bloomOrder;
  final bool reduceMotion;

  @override
  State<_LoveFlower> createState() => _LoveFlowerState();
}

class _LoveFlowerState extends State<_LoveFlower>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  bool get _animate => widget.isNew && !widget.reduceMotion;

  @override
  void initState() {
    super.initState();
    if (_animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 540),
      );
      // 140ms stagger per new flower (design §4).
      Future<void>.delayed(
        Duration(milliseconds: 140 * widget.bloomOrder),
        () {
          if (mounted) {
            _controller?.forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flower = _buildFlower();
    if (!_animate || _controller == null) {
      return flower;
    }

    // Petals: scale 0→1 + fade over the whole 540ms (easeOutBack).
    final petalScale = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutBack,
    );
    final petalFade = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    // Nucleus pops in slightly later (≈120ms / 540 ≈ 0.22).
    final nucleusScale = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.22, 1.0, curve: Curves.easeOutBack),
    );

    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        return Opacity(
          opacity: petalFade.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: petalScale.value.clamp(0.0, 1.2),
            child: _buildFlowerAnimated(nucleusScale.value.clamp(0.0, 1.2)),
          ),
        );
      },
    );
  }

  Widget _buildFlower() => _buildFlowerAnimated(1.0);

  Widget _buildFlowerAnimated(double nucleusScale) {
    final d = widget.diameter;
    final nucleusD = d * 0.59; // ≈20px on a 34px flower
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Petals.
          CustomPaint(
            size: Size(d, d),
            painter: _FlowerPetalsPainter(
              edgeColor: LoveTreeService.petalEdge(widget.kind),
            ),
          ),
          // Nucleus disc with the Lucide / Material icon.
          Transform.scale(
            scale: nucleusScale,
            child: _Nucleus(kind: widget.kind, diameter: nucleusD),
          ),
        ],
      ),
    );
  }
}

class _Nucleus extends StatelessWidget {
  const _Nucleus({required this.kind, required this.diameter});

  final FlowerKind kind;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final color = LoveTreeService.nucleusColor(kind);
    final gradient = kind == FlowerKind.streak
        ? const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sunset2, AppColors.accentLoveDeep],
          )
        : null;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: gradient == null ? color : null,
        gradient: gradient,
        border: Border.all(color: AppColors.white.withValues(alpha: 0.60), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          LoveTreeService.nucleusIcon(kind),
          size: diameter * 0.6,
          color: AppColors.white,
        ),
      ),
    );
  }
}

/// Paints the 5 soft teardrop petals of a flower, rotated 72° apart, each a
/// radial gradient from a soft pink centre out to [edgeColor].
class _FlowerPetalsPainter extends CustomPainter {
  _FlowerPetalsPainter({required this.edgeColor});

  final Color edgeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Petal geometry: it grows OUT from a little above centre.
    final petalLen = size.height * 0.46;
    final petalW = size.width * 0.30;

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.white.withValues(alpha: 0.35);

    for (int i = 0; i < 5; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * (2 * math.pi / 5));

      // Teardrop petal pointing up (−y), tip at -petalLen.
      final path = Path()
        ..moveTo(0, -size.height * 0.05)
        ..quadraticBezierTo(-petalW, -petalLen * 0.55, 0, -petalLen)
        ..quadraticBezierTo(petalW, -petalLen * 0.55, 0, -size.height * 0.05)
        ..close();

      final fill = Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFD6E0), edgeColor],
        ).createShader(
          Rect.fromCircle(center: Offset.zero, radius: petalLen),
        );

      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FlowerPetalsPainter oldDelegate) =>
      oldDelegate.edgeColor != edgeColor;
}

// ───────────────────────────────────────────────────────────────────────────
// Tree painter — trunk / canopy (blob) / leaves / mound / bokeh per stage
// ───────────────────────────────────────────────────────────────────────────

class LoveTreePainter extends CustomPainter {
  LoveTreePainter({required this.stage, this.skeleton = false});

  final LoveTreeStage stage;

  /// Loading skeleton → paint trunk + canopy in flat grey (no gradient/leaves).
  final bool skeleton;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final base = Offset(w * 0.5, h * 0.92);

    _paintBokeh(canvas, size);
    _paintMound(canvas, size, base);

    if (stage == LoveTreeStage.seed) {
      _paintSeedling(canvas, size, base);
      return;
    }
    _paintTree(canvas, size, base);
  }

  // ── Background ─────────────────────────────────────────────────────────────

  void _paintBokeh(Canvas canvas, Size size) {
    if (skeleton) {
      return;
    }
    // Fixed positions (fractions of size) so they never jitter between builds.
    const spots = <List<double>>[
      [0.18, 0.16, 5, 0.18],
      [0.30, 0.30, 3, 0.14],
      [0.72, 0.14, 6, 0.20],
      [0.82, 0.32, 4, 0.16],
      [0.55, 0.10, 4, 0.22],
      [0.40, 0.08, 3, 0.14],
      [0.65, 0.26, 7, 0.16],
    ];
    for (final s in spots) {
      final paint = Paint()
        ..color = AppColors.white.withValues(alpha: s[3]);
      canvas.drawCircle(
        Offset(size.width * s[0], size.height * s[1]),
        s[2],
        paint,
      );
    }
  }

  void _paintMound(Canvas canvas, Size size, Offset base) {
    final w = size.width;
    final h = size.height;
    final top = h * 0.92 - h * 0.04;
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, top + h * 0.04)
      ..quadraticBezierTo(w * 0.5, top - h * 0.06, w, top + h * 0.04)
      ..lineTo(w, h)
      ..close();

    final fill = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x8CE8B4D8), // accentGold .55
          Color(0x4DA78BFA), // accentLavender .30
        ],
      ).createShader(Rect.fromLTWH(0, top - h * 0.06, w, h * 0.16));
    canvas.drawPath(path, fill);

    // Thin highlight along the mound crest.
    final crest = Path()
      ..moveTo(0, top + h * 0.04)
      ..quadraticBezierTo(w * 0.5, top - h * 0.06, w, top + h * 0.04);
    canvas.drawPath(
      crest,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = AppColors.white.withValues(alpha: 0.25),
    );
  }

  // ── Seedling (S0) ──────────────────────────────────────────────────────────

  void _paintSeedling(Canvas canvas, Size size, Offset base) {
    final h = size.height;
    final stemColor = skeleton ? AppColors.surfaceLight : const Color(0xFF7BA86A);
    final stemTop = Offset(base.dx, base.dy - h * 0.12);

    // S-curved short stem.
    final stem = Path()
      ..moveTo(base.dx, base.dy)
      ..cubicTo(
        base.dx - 8, base.dy - h * 0.04,
        base.dx + 8, base.dy - h * 0.08,
        stemTop.dx, stemTop.dy,
      );
    canvas.drawPath(
      stem,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..color = stemColor,
    );

    if (skeleton) {
      return;
    }

    // Two cotyledon leaves at the tip.
    _paintLeaf(canvas, stemTop, h * 0.10, -35, const [Color(0xFF8FCB7A), Color(0xFF66A85C)]);
    _paintLeaf(canvas, stemTop, h * 0.10, 35, const [Color(0xFF8FCB7A), Color(0xFF66A85C)]);
  }

  // ── Full tree (S1+) ──────────────────────────────────────────────────────────

  void _paintTree(Canvas canvas, Size size, Offset base) {
    final w = size.width;
    final h = size.height;

    final spec = _specForStage(stage);

    // Trunk.
    final trunkTop = Offset(base.dx, base.dy - h * spec.trunkHeight);
    final trunkColor = skeleton ? AppColors.surfaceLight : spec.trunkColor;
    final trunk = Path()
      ..moveTo(base.dx - spec.trunkBase, base.dy)
      ..quadraticBezierTo(
        base.dx - spec.trunkBase * 0.4, base.dy - h * spec.trunkHeight * 0.5,
        trunkTop.dx - spec.trunkTop, trunkTop.dy,
      )
      ..lineTo(trunkTop.dx + spec.trunkTop, trunkTop.dy)
      ..quadraticBezierTo(
        base.dx + spec.trunkBase * 0.4, base.dy - h * spec.trunkHeight * 0.5,
        base.dx + spec.trunkBase, base.dy,
      )
      ..close();
    canvas.drawPath(trunk, Paint()..color = trunkColor);

    // Branches.
    for (final dir in spec.branchDirs) {
      final start = Offset(base.dx, base.dy - h * spec.trunkHeight * 0.65);
      final end = Offset(
        base.dx + dir * w * 0.14,
        base.dy - h * spec.trunkHeight * 0.92,
      );
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(
            (start.dx + end.dx) / 2 + dir * 6,
            start.dy - h * 0.02,
            end.dx,
            end.dy,
          ),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = spec.branchWidth
          ..strokeCap = StrokeCap.round
          ..color = trunkColor,
      );
    }

    // Canopy centre.
    final canopyCenter = Offset(base.dx, base.dy - h * spec.trunkHeight - spec.canopyR * 0.35);
    final canopyR = spec.canopyR;

    // Glow behind the canopy (bloom stage only).
    if (stage == LoveTreeStage.bloom && !skeleton) {
      final glow = Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.accentRose.withValues(alpha: 0.10),
            AppColors.accentRose.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: canopyCenter, radius: canopyR * 1.25));
      canvas.drawCircle(canopyCenter, canopyR * 1.25, glow);
    }

    // Canopy drop shadow (S6+).
    if (spec.hasShadow && !skeleton) {
      final shadowPath = _blobPath(
        Offset(canopyCenter.dx - 6, canopyCenter.dy + 8),
        canopyR,
        spec.bumps,
      );
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = const Color(0xFF3D6B33).withValues(alpha: 0.12)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Canopy blob.
    final canopyPath = _blobPath(canopyCenter, canopyR, spec.bumps);
    if (skeleton) {
      canvas.drawPath(canopyPath, Paint()..color = AppColors.surfaceLight);
      return;
    }
    final canopyFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [spec.canopyLight, spec.canopyDark],
      ).createShader(Rect.fromCircle(center: canopyCenter, radius: canopyR));
    canvas.drawPath(canopyPath, canopyFill);

    // Leaves dotted around the rim.
    final leafColors = [spec.canopyDark, _darken(spec.canopyDark)];
    for (int i = 0; i < spec.leafCount; i++) {
      final a = i * (2 * math.pi / spec.leafCount) + 0.3;
      final lp = Offset(
        canopyCenter.dx + math.cos(a) * canopyR * 0.92,
        canopyCenter.dy + math.sin(a) * canopyR * 0.62,
      );
      _paintLeaf(canvas, lp, canopyR * 0.22, a * 180 / math.pi + 90, leafColors);
    }

    // Fallen petals around the base (bloom stage flourish).
    if (stage == LoveTreeStage.bloom) {
      const fallen = <List<double>>[
        [0.32, 0.86],
        [0.66, 0.88],
        [0.50, 0.90],
        [0.42, 0.84],
      ];
      for (final f in fallen) {
        final p = Offset(w * f[0], h * f[1]);
        _paintLeaf(canvas, p, h * 0.018, 20,
            const [Color(0xFFFFD6E0), Color(0xFFFF8FA3)]);
      }
    }
  }

  // ── Primitives ─────────────────────────────────────────────────────────────

  /// A soft "cloud" blob: points on an ellipse pushed in/out by a fixed bump
  /// table, joined with cubic beziers for a wavy organic rim.
  Path _blobPath(Offset center, double radius, List<double> bumps) {
    final n = bumps.length;
    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final a = i * (2 * math.pi / n) - math.pi / 2;
      final r = radius * bumps[i];
      // Flatten vertically a touch so the canopy reads as a wide cloud.
      pts.add(Offset(
        center.dx + math.cos(a) * r,
        center.dy + math.sin(a) * r * 0.78,
      ));
    }
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < n; i++) {
      final cur = pts[i];
      final next = pts[(i + 1) % n];
      final mid = Offset((cur.dx + next.dx) / 2, (cur.dy + next.dy) / 2);
      path.quadraticBezierTo(cur.dx, cur.dy, mid.dx, mid.dy);
    }
    path.close();
    return path;
  }

  /// A teardrop leaf of [len] at [angleDeg] around [at], filled with a vertical
  /// gradient + a thin white vein.
  void _paintLeaf(
    Canvas canvas,
    Offset at,
    double len,
    double angleDeg,
    List<Color> colors,
  ) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angleDeg * math.pi / 180);
    final wdt = len * 0.55;
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-wdt, -len * 0.5, 0, -len)
      ..quadraticBezierTo(wdt, -len * 0.5, 0, 0)
      ..close();
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromLTWH(-wdt, -len, wdt * 2, len));
    canvas.drawPath(path, fill);
    // Vein.
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, -len * 0.9),
      Paint()
        ..strokeWidth = 0.8
        ..color = AppColors.white.withValues(alpha: 0.20),
    );
    canvas.restore();
  }

  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0)).toColor();
  }

  /// The canopy centre + radius (in canvas px) for [stage] on a canvas of
  /// [size] — exposed so the flower overlay ([_TreeHero._bloomPositions]) can
  /// anchor blooms to the SAME canopy the painter draws. Mirrors the geometry in
  /// [_paintTree].
  static (Offset, double) canopyGeometry(LoveTreeStage stage, Size size) {
    final spec = _specForStage(stage);
    final base = Offset(size.width * 0.5, size.height * 0.92);
    // Seedling has no canopy — give a tiny notional one around the tip so a
    // (rare) stray flower would still sit sensibly; seed stage has 0 flowers.
    final canopyR = spec.canopyR <= 0 ? size.width * 0.18 : spec.canopyR;
    final center = Offset(
      base.dx,
      base.dy - size.height * spec.trunkHeight - canopyR * 0.35,
    );
    return (center, canopyR);
  }

  static _StageSpec _specForStage(LoveTreeStage stage) {
    switch (stage) {
      case LoveTreeStage.seed:
        return _StageSpec(
          trunkHeight: 0.12,
          trunkBase: 4,
          trunkTop: 2,
          canopyR: 0,
          bumps: const [],
          leafCount: 0,
          branchDirs: const [],
          branchWidth: 0,
          trunkColor: const Color(0xFF7BA86A),
          canopyLight: const Color(0xFFA8D88F),
          canopyDark: const Color(0xFF7CB86A),
          hasShadow: false,
        );
      case LoveTreeStage.sprout:
        return _StageSpec(
          trunkHeight: 0.28,
          trunkBase: 7,
          trunkTop: 3,
          canopyR: 64,
          bumps: const [1.0, 0.86, 1.05, 0.9, 1.0],
          leafCount: 5,
          branchDirs: const [],
          branchWidth: 4,
          trunkColor: const Color(0xFF9B7B5A),
          canopyLight: const Color(0xFFA8D88F),
          canopyDark: const Color(0xFF7CB86A),
          hasShadow: false,
        );
      case LoveTreeStage.young:
        return _StageSpec(
          trunkHeight: 0.42,
          trunkBase: 10,
          trunkTop: 4,
          canopyR: 92,
          bumps: const [1.0, 0.82, 1.08, 0.86, 1.04, 0.9],
          leafCount: 9,
          branchDirs: const [1],
          branchWidth: 5,
          trunkColor: const Color(0xFF8B6B4A),
          canopyLight: const Color(0xFF9FD47F),
          canopyDark: const Color(0xFF6FAF5C),
          hasShadow: false,
        );
      case LoveTreeStage.green:
        return _StageSpec(
          trunkHeight: 0.48,
          trunkBase: 13,
          trunkTop: 5,
          canopyR: 120,
          bumps: const [1.0, 0.82, 1.1, 0.84, 1.08, 0.86, 1.04, 0.9],
          leafCount: 13,
          branchDirs: const [-1, 1],
          branchWidth: 6,
          trunkColor: const Color(0xFF7A5A3C),
          canopyLight: const Color(0xFF92CF72),
          canopyDark: const Color(0xFF5FA84F),
          hasShadow: true,
        );
      case LoveTreeStage.bloom:
        return _StageSpec(
          trunkHeight: 0.48,
          trunkBase: 15,
          trunkTop: 6,
          canopyR: 140,
          bumps: const [1.0, 0.8, 1.12, 0.84, 1.1, 0.82, 1.06, 0.88, 1.04, 0.9],
          leafCount: 15,
          branchDirs: const [-1, 1],
          branchWidth: 7,
          trunkColor: const Color(0xFF6E5236),
          canopyLight: const Color(0xFF8FCF6E),
          canopyDark: const Color(0xFF57A347),
          hasShadow: true,
        );
    }
  }

  @override
  bool shouldRepaint(LoveTreePainter oldDelegate) =>
      oldDelegate.stage != stage || oldDelegate.skeleton != skeleton;
}

/// Geometry + colour table for a tree stage (keeps [LoveTreePainter] readable).
class _StageSpec {
  const _StageSpec({
    required this.trunkHeight,
    required this.trunkBase,
    required this.trunkTop,
    required this.canopyR,
    required this.bumps,
    required this.leafCount,
    required this.branchDirs,
    required this.branchWidth,
    required this.trunkColor,
    required this.canopyLight,
    required this.canopyDark,
    required this.hasShadow,
  });

  /// Trunk height as a fraction of canvas height.
  final double trunkHeight;
  final double trunkBase;
  final double trunkTop;
  final double canopyR;

  /// Per-vertex radius multipliers for the canopy blob (length = vertex count).
  final List<double> bumps;
  final int leafCount;

  /// Branch directions (−1 left, +1 right).
  final List<int> branchDirs;
  final double branchWidth;
  final Color trunkColor;
  final Color canopyLight;
  final Color canopyDark;
  final bool hasShadow;
}
