import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/photo.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../providers/streak_provider.dart';
import '../services/love_tree_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/content_card.dart';
import '../widgets/entrance_reveal.dart';
import '../widgets/header_icon_button.dart';
import '../widgets/icon_badge.dart';
import '../widgets/ink_tile.dart';
import '../widgets/moment_sheet.dart';
import '../widgets/shimmer_skeleton.dart';
import '../widgets/sub_screen_header.dart';

// ── Living-tree environment (v2 #2) ──────────────────────────────────────────

/// Time-of-day sky band (design §B.1).
enum SkyPhase { dawn, day, dusk, night }

/// Season band (design §B.3).
enum Season { spring, summer, autumn, winter }

SkyPhase skyPhaseForHour(int hour) {
  if (hour >= 5 && hour < 9) return SkyPhase.dawn;
  if (hour >= 9 && hour < 16) return SkyPhase.day;
  if (hour >= 16 && hour < 19) return SkyPhase.dusk;
  return SkyPhase.night;
}

Season seasonForMonth(int month) {
  if (month >= 2 && month <= 4) return Season.spring;
  if (month >= 5 && month <= 7) return Season.summer;
  if (month >= 8 && month <= 10) return Season.autumn;
  return Season.winter; // 11, 12, 1
}

// Share-card dimensions (v2 #3): a 4:5 portrait card, rendered at a small
// logical width then exported at ~1080×1350 for crisp social sharing.
const double _kShareCardWidth = 360.0;
const double _kShareCardExportWidth = 1080.0;

/// Resolves the photo behind a `photos` milestone of [value] (the `value`-th
/// OLDEST photo). [PhotoProvider.sortedPhotos] runs newest→oldest, so the
/// `value`-th oldest sits at `length - value`. Returns null when the server
/// aggregate count exceeds the loaded photos (index out of range) — the moment
/// sheet then hides the thumbnail/CTA without crashing (PO/design guard).
Photo? resolvePhotoForMilestone(PhotoProvider photo, int value) {
  final list = photo.sortedPhotos;
  final index = list.length - value;
  if (index < 0 || index >= list.length) {
    return null;
  }
  return list[index];
}

/// Opens the [MomentSheet] for a tapped flower / reached milestone — resolves
/// the per-kind data (bloom date for days, photo + date for photos).
void _openMomentSheet(
  BuildContext context,
  LoveTreeMilestone m, {
  required DateTime anniversary,
  required PhotoProvider photo,
}) {
  switch (m.kind) {
    case FlowerKind.days:
      MomentSheet.showBloomed(
        context,
        kind: m.kind,
        value: m.value,
        bloomDate: anniversary.add(Duration(days: m.value)),
      );
      break;
    case FlowerKind.streak:
      MomentSheet.showBloomed(context, kind: m.kind, value: m.value);
      break;
    case FlowerKind.photos:
      final p = resolvePhotoForMilestone(photo, m.value);
      MomentSheet.showBloomed(
        context,
        kind: m.kind,
        value: m.value,
        photo: p,
        photoDate: p?.uploadDate,
      );
      break;
  }
}

/// Resolved garden state for one build — shared by the header (share button)
/// and the body so they never disagree.
class _TreeData {
  const _TreeData({
    required this.couple,
    required this.days,
    required this.longestStreak,
    required this.photoCount,
    required this.milestones,
    required this.reached,
    required this.flowerCount,
    required this.stage,
  });

  final Couple couple;
  final int days;
  final int longestStreak;
  final int photoCount;
  final List<LoveTreeMilestone> milestones;
  final List<LoveTreeMilestone> reached;
  final int flowerCount;
  final LoveTreeStage stage;
}

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

class _LoveTreeScreenState extends State<LoveTreeScreen>
    with SingleTickerProviderStateMixin {
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

  /// Whether the one-shot "tap a flower" coach mark may show this visit (read
  /// once at entry; cleared as soon as the coach is dismissed so a late rebuild
  /// can't re-arm it). The body only shows it when there's also ≥1 flower.
  bool _coachEligible = false;
  bool _coachDismissed = false;

  /// Sky + season chosen ONCE at entry (v2 #2) — not ticked per second (saves
  /// battery; "the tree changes when you reopen" is enough).
  late final SkyPhase _phase = skyPhaseForHour(DateTime.now().hour);
  late final Season _season = seasonForMonth(DateTime.now().month);

  /// One shared controller drives every idle particle + flower sway (B.6 — at
  /// most 1–2 controllers, never one per particle).
  AnimationController? _ambient;

  /// Off-screen render target for the "share our tree" card (v2 #3).
  final GlobalKey _shareCardKey = GlobalKey();
  bool _renderingShareCard = false;
  _ShareCardData? _shareCardData;
  bool _sharing = false;

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
      _coachEligible = !LoveTreeService.coachShown(_coupleId!);
    }
  }

  /// Called once the coach mark is dismissed (tap anywhere / auto-timeout) —
  /// stamps the Hive flag so it never shows again, even if the user never
  /// tapped a flower.
  void _dismissCoach() {
    if (_coachDismissed) {
      return;
    }
    _coachDismissed = true;
    if (_coupleId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        LoveTreeService.markCoachShown(_coupleId!);
      });
    }
    if (mounted) {
      setState(() => _coachEligible = false);
    }
  }

  /// Lazily created the first time the tree is shown with motion enabled — a
  /// slow repeating clock (8s) the particles/sway read by phase offset.
  AnimationController _ambientController() {
    return _ambient ??= AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ambient?.dispose();
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

    // Resolve the garden once so the header (share button visibility) and the
    // body agree. Null → a non-garden state (no-couple / waiting / loading).
    final data = _resolveTree(couple, streak, photo);

    // The share button shows only for an active couple that has a garden.
    final canShare = data != null;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: SubScreenHeader(
                      badge: l10n.loveTreeBadge,
                      badgeIcon: IconsaxPlusLinear.magic_star,
                      trailing: canShare
                          ? HeaderIconButton(
                              icon: IconsaxPlusLinear.share,
                              iconColor: AppColors.accentLoveDeep,
                              semanticsLabel: l10n.loveTreeShareButton,
                              onTap: () => _shareTree(context, data),
                            )
                          : null,
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
                      data: data,
                    ),
                  ),
                ],
              ),

              // Off-screen render target for the share card. Positioned far off
              // the visible area so it lays out at its fixed logical size but is
              // never seen — captured to a PNG on demand.
              if (_renderingShareCard && _shareCardData != null)
                Positioned(
                  left: -3000,
                  top: 0,
                  child: RepaintBoundary(
                    key: _shareCardKey,
                    child: _LoveTreeShareCard(
                      width: _kShareCardWidth,
                      data: _shareCardData!,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Computes the garden data once. Returns null for non-garden states
  /// (no-couple / waiting / first streak load), which the body renders as a
  /// message/skeleton and the header reads to hide the share button.
  _TreeData? _resolveTree(
    Couple? couple,
    StreakProvider streak,
    PhotoProvider photo,
  ) {
    if (couple == null || couple.isWaitingForPartner) {
      return null;
    }
    final streakLoading =
        streak.isLoading && streak.state == StreakState.hidden;
    if (streakLoading) {
      return null;
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

    return _TreeData(
      couple: couple,
      days: days,
      longestStreak: longestStreak,
      photoCount: photoCount,
      milestones: milestones,
      reached: reached,
      flowerCount: flowerCount,
      stage: LoveTreeService.stageForFlowers(flowerCount),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n, {
    required Couple? couple,
    required StreakProvider streak,
    required PhotoProvider photo,
    required bool reduceMotion,
    required _TreeData? data,
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
    if (data == null) {
      return const _LoadingTree();
    }

    final flowerCount = data.flowerCount;
    final reached = data.reached;
    final stage = data.stage;

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

    // The ambient clock only spins when there's any motion to drive.
    final ambient = reduceMotion ? null : _ambientController();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. The tree hero (sky + season + idle particles + tappable flowers
          //    + the one-shot coach mark).
          _TreeHero(
            stage: stage,
            reached: reached,
            newFromIndexInReached: flowerCount - newCount,
            reduceMotion: reduceMotion,
            confetti: _confetti,
            phase: _phase,
            season: _season,
            ambient: ambient,
            anniversary: data.couple.anniversaryDate,
            photoProvider: photo,
            // Coach mark: only when eligible (flag not set) AND there are
            // flowers to point at; delayed past any bloom in `_TreeHero`.
            showCoach: _coachEligible && flowerCount > 0,
            hasNewBlooms: hasNewBlooms,
            onCoachDismissed: _dismissCoach,
          ),

          // 2. Caption (permanent affordance — only when there are flowers).
          if (flowerCount > 0) ...[
            const SizedBox(height: 10),
            _TapHintCaption(l10n: l10n),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 16),

          // 3. Stage title + flower count.
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

          // 4. Bloom banner (only when there are new flowers).
          if (hasNewBlooms) ...[
            const SizedBox(height: 16),
            _BloomBanner(
              count: newCount,
              reduceMotion: reduceMotion,
              onShare: () => _shareTree(context, data),
            ),
          ],

          const SizedBox(height: 20),

          // 5. "Grow it together".
          EntranceReveal(order: 1, child: _NurtureCard(l10n: l10n)),
          const SizedBox(height: 16),

          // 6. Milestones.
          EntranceReveal(
            order: 2,
            child: _MilestonesCard(
              l10n: l10n,
              milestones: data.milestones,
              days: data.days,
              longestStreak: data.longestStreak,
              photoCount: data.photoCount,
              anniversary: data.couple.anniversaryDate,
              photoProvider: photo,
            ),
          ),
        ],
      ),
    );
  }

  /// Renders the share card off-screen → PNG → OS share sheet (v2 #3). Errors
  /// stay silent (no toast) like [InviteActionButtons]. [origin] feeds the iPad
  /// popover anchor.
  Future<void> _shareTree(BuildContext context, _TreeData data) async {
    if (_sharing) {
      return;
    }
    _sharing = true;
    HapticFeedback.selectionClick();

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final nf = NumberFormat.decimalPattern(locale);

    // Anchor the iPad popover to the whole screen (the tap originates from a
    // small header icon; the screen rect is a safe, always-valid anchor).
    final box = context.findRenderObject() as RenderBox?;
    final origin = (box != null && box.hasSize)
        ? (box.localToGlobal(Offset.zero) & box.size)
        : null;

    final cardData = _ShareCardData(
      stage: data.stage,
      reached: data.reached,
      person1Name: data.couple.person1Name,
      person2Name: data.couple.person2Name,
      creatorUserId: data.couple.createdByUserId,
      statsLine: l10n.loveTreeShareStats(
        nf.format(data.days),
        nf.format(data.flowerCount),
      ),
      tagline: data.flowerCount == 0
          ? l10n.loveTreeShareTaglineSeed
          : l10n.loveTreeShareTagline,
    );

    setState(() {
      _shareCardData = cardData;
      _renderingShareCard = true;
    });

    try {
      // Let the off-screen card lay out + paint for a couple of frames before
      // capturing.
      await WidgetsBinding.instance.endOfFrame;
      await Future<void>.delayed(const Duration(milliseconds: 40));

      final bytes = await _captureShareCard();
      if (bytes == null) {
        return;
      }

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/love_tree_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes);

      final message = l10n.loveTreeShareMessage(
        nf.format(data.flowerCount),
        nf.format(data.days),
      );
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: message,
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      // Rare, OS-driven; stay silent per design (no error toast).
    } finally {
      _sharing = false;
      if (mounted) {
        setState(() => _renderingShareCard = false);
      }
    }
  }

  /// Captures the off-screen [_LoveTreeShareCard] to PNG bytes at ~1080px wide.
  Future<Uint8List?> _captureShareCard() async {
    final boundary = _shareCardKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) {
      return null;
    }
    final image = await boundary.toImage(
      pixelRatio: _kShareCardExportWidth / _kShareCardWidth,
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
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

// Base flower diameter ≈34px; small flowers near the rim scale to 0.82.
double _flowerDiameter(int index, int count) {
  const base = 34.0;
  // Outer-ring flowers (later half) shrink slightly for a layered canopy.
  final outer = count > 1 && index >= count * 0.6;
  return outer ? base * 0.82 : base;
}

double _flowerRadius(int index, int count) => _flowerDiameter(index, count) / 2;

/// Transparent hit-target padding around a flower so even the small (28px)
/// rim flowers get a ≥44px tap area (design §A.1). The visible flower is NOT
/// enlarged — only the touch box.
double _flowerHitPad(double diameter) =>
    ((44.0 - diameter) / 2).clamp(0.0, 22.0);

/// Deterministic flower layout — delegated to the active [kTreeRenderer] so the
/// "what/where" stays renderer-agnostic. For v2.1 ([PaintTreeRenderer]) this is
/// the golden-angle phyllotaxis anchored to the canopy; for v2.2
/// ([SakuraBranchRenderer]) it anchors blossoms ALONG the branch. Either way the
/// result is deterministic per index (no runtime randomness → flowers never
/// shuffle between builds). Shared by the on-screen hero and the share card so
/// both lay flowers out identically.
List<Offset> bloomPositions(LoveTreeStage stage, Size size, int count) =>
    kTreeRenderer.bloomPositions(stage, size, count);

/// Phyllotaxis anchored to the stage canopy ([PaintTreeRenderer], v2.1).
List<Offset> _canopyBloomPositions(LoveTreeStage stage, Size size, int count) {
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
    final jx = (_bloomHash(i) % 7) - 3; // -3..+3 (fixed per index)
    final jy = (_bloomHash(i * 31 + 7) % 7) - 3;
    final x = center.dx + radius * math.cos(angle) + jx;
    // Flatten vertically (0.7) so flowers fan across the wide cloud canopy.
    final y = center.dy + radius * math.sin(angle) * 0.7 + jy;
    out.add(Offset(x, y));
  }
  return out;
}

int _bloomHash(int i) {
  // Knuth multiplicative hash, kept positive — stable per index.
  var h = (i * 2654435761) & 0x7fffffff;
  h = (h >> 13) ^ h;
  return h & 0x7fffffff;
}

class _TreeHero extends StatelessWidget {
  const _TreeHero({
    required this.stage,
    required this.reached,
    required this.newFromIndexInReached,
    required this.reduceMotion,
    required this.confetti,
    required this.phase,
    required this.season,
    required this.ambient,
    required this.anniversary,
    required this.photoProvider,
    required this.showCoach,
    required this.hasNewBlooms,
    required this.onCoachDismissed,
  });

  final LoveTreeStage stage;

  /// Reached milestones in stable order (== the flowers, oldest first).
  final List<LoveTreeMilestone> reached;

  /// Index within [reached] from which flowers are "new" this visit (bloom).
  final int newFromIndexInReached;

  final bool reduceMotion;
  final ConfettiController confetti;

  /// Sky band + season chosen at entry (v2 #2).
  final SkyPhase phase;
  final Season season;

  /// Shared idle clock (null under Reduce Motion).
  final AnimationController? ambient;

  /// For the per-flower moment sheet (days bloom date / photo lookup).
  final DateTime anniversary;
  final PhotoProvider photoProvider;

  /// Whether to show the one-shot "tap a flower" coach mark this visit (v2.1).
  final bool showCoach;

  /// True when this visit is also animating new blooms — the coach waits for
  /// them to finish before appearing.
  final bool hasNewBlooms;

  /// Called when the coach is dismissed (tap anywhere / auto-timeout) so the
  /// screen can stamp the per-couple Hive flag.
  final VoidCallback onCoachDismissed;

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
          final positions = bloomPositions(stage, size, reached.length);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1+2. Sky gradient + static stars (night) — painted BELOW the
              // tree; repaints only when phase/season/size change.
              Positioned.fill(
                child: CustomPaint(
                  painter: SkyBackdropPainter(phase: phase, season: season),
                ),
              ),

              // 3. The tree itself (branch / buds / leaves) — the active
              // renderer decides whether that's a canopy tree or a sakura
              // branch.
              Positioned.fill(
                child: CustomPaint(
                  painter: kTreeRenderer.treePainter(
                    stage: stage,
                    season: season,
                  ),
                ),
              ),

              // 4. Flowers — drawn bottom-up so upper flowers overlap lower
              // ones. Keyed by milestone identity so a flower's State is never
              // recycled as a different flower when the list grows mid-visit.
              for (int i = 0; i < reached.length; i++)
                Positioned(
                  key: ValueKey('${reached[i].kind}-${reached[i].value}'),
                  // Offset by radius + hit-pad so the VISIBLE flower stays
                  // centred on its slot even though the touch box is padded.
                  left: positions[i].dx -
                      _flowerRadius(i, reached.length) -
                      _flowerHitPad(_flowerDiameter(i, reached.length)),
                  top: positions[i].dy -
                      _flowerRadius(i, reached.length) -
                      _flowerHitPad(_flowerDiameter(i, reached.length)),
                  child: kTreeRenderer.flowerWidget(
                    kind: reached[i].kind,
                    diameter: _flowerDiameter(i, reached.length),
                    isNew: i >= newFromIndexInReached,
                    // Cap the visible stagger at 6 new flowers (design §4).
                    bloomOrder: (i - newFromIndexInReached).clamp(0, 6),
                    reduceMotion: reduceMotion,
                    swayPhase: i * 0.6,
                    ambient: ambient,
                    onTap: () => _openMomentSheet(
                      context,
                      reached[i],
                      anniversary: anniversary,
                      photo: photoProvider,
                    ),
                  ),
                ),

              // 5. Idle particles (fireflies at night, falling petals/leaves in
              // spring/autumn, otherwise none). Static under Reduce Motion.
              Positioned.fill(
                child: IgnorePointer(
                  child: _AmbientParticles(
                    phase: phase,
                    season: season,
                    reduceMotion: reduceMotion,
                    ambient: ambient,
                  ),
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

              // One-shot coach mark: ripple + tap-dot + tooltip over the flower
              // nearest the canopy top (v2.1 §B.1). Sits above the flowers in
              // the same coordinate space; a transparent catcher dismisses it on
              // any tap. Built only when eligible + there is a target.
              if (showCoach && positions.isNotEmpty)
                _TapCoachMark(
                  target: positions[_coachTargetIndex(positions)],
                  flowerDiameter: _flowerDiameter(
                    _coachTargetIndex(positions),
                    reached.length,
                  ),
                  reduceMotion: reduceMotion,
                  startDelay: Duration(
                    milliseconds: hasNewBlooms ? 1200 : 350,
                  ),
                  onDismiss: onCoachDismissed,
                ),
            ],
          );
        },
      ),
    );
  }

  /// The flower the coach should point at (v2.1 §B.1.2): the one nearest the
  /// canopy TOP (smallest `dy`, i.e. highest on screen), tie-broken by closeness
  /// to the horizontal centre. Deterministic — picks an easy-to-see,
  /// unobstructed bloom rather than the (possibly rim-bound) newest one.
  static int _coachTargetIndex(List<Offset> positions) {
    final centerX =
        positions.map((p) => p.dx).fold<double>(0, (a, b) => a + b) /
            positions.length;
    var best = 0;
    var bestDy = positions[0].dy;
    var bestDx = (positions[0].dx - centerX).abs();
    for (var i = 1; i < positions.length; i++) {
      final p = positions[i];
      final dxFromCentre = (p.dx - centerX).abs();
      if (p.dy < bestDy - 0.5 ||
          ((p.dy - bestDy).abs() <= 0.5 && dxFromCentre < bestDx)) {
        best = i;
        bestDy = p.dy;
        bestDx = dxFromCentre;
      }
    }
    return best;
  }
}

// ───────────────────────────────────────────────────────────────────────────
// Coach mark (v2.1 §B.1) — one-shot "tap a flower" hint
// ───────────────────────────────────────────────────────────────────────────

/// The one-shot coach mark overlaid on the tree hero: a pulsing ripple + tap-dot
/// around [target] plus a dark tooltip pointing at it. A transparent full-area
/// catcher dismisses it on any tap; it also auto-dismisses after 4s. Under
/// Reduce Motion the ripple/tap-dot are drawn STATIC (a single ring + dot),
/// the tooltip still shows, and it still auto-dismisses. The visible flower is
/// NOT moved — this only annotates it.
class _TapCoachMark extends StatefulWidget {
  const _TapCoachMark({
    required this.target,
    required this.flowerDiameter,
    required this.reduceMotion,
    required this.startDelay,
    required this.onDismiss,
  });

  /// Centre of the target flower in the hero's coordinate space.
  final Offset target;
  final double flowerDiameter;
  final bool reduceMotion;

  /// Delay before fading in (lets any bloom animation finish first).
  final Duration startDelay;

  /// Called once when the coach is dismissed (tap / timeout).
  final VoidCallback onDismiss;

  @override
  State<_TapCoachMark> createState() => _TapCoachMarkState();
}

class _TapCoachMarkState extends State<_TapCoachMark>
    with TickerProviderStateMixin {
  /// Drives the ripple + tap-dot pulse (only when motion is on).
  AnimationController? _pulse;

  /// Fade in/out of the whole coach cluster.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  bool _visible = false;
  bool _dismissed = false;
  Timer? _showTimer;
  Timer? _autoHideTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat();
    }
    // Fade in after the start delay, then arm the 4s auto-hide.
    _showTimer = Timer(widget.startDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _visible = true);
      _fade.duration = const Duration(milliseconds: 280);
      _fade.forward();
      _autoHideTimer = Timer(const Duration(milliseconds: 4000), _hide);
    });
  }

  void _hide() {
    if (_dismissed || !mounted) {
      return;
    }
    _dismissed = true;
    _autoHideTimer?.cancel();
    _fade.duration = const Duration(milliseconds: 220);
    _fade.reverse();
    // Stamp the flag immediately (best-effort) regardless of fade timing.
    widget.onDismiss();
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _autoHideTimer?.cancel();
    _pulse?.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible && !_dismissed) {
      return const SizedBox.shrink();
    }
    return Positioned.fill(
      child: GestureDetector(
        // Catch a tap anywhere to dismiss; translucent so the visual layer
        // below isn't blocked, and the next tap reaches the flower.
        behavior: HitTestBehavior.opaque,
        onTap: _hide,
        child: FadeTransition(
          opacity: _fade,
          child: _pulse == null
              ? CustomPaint(
                  painter: _CoachPainter(
                    target: widget.target,
                    flowerDiameter: widget.flowerDiameter,
                    t: -1, // static (Reduce Motion)
                  ),
                  size: Size.infinite,
                  child: _tooltipLayer(context),
                )
              : AnimatedBuilder(
                  animation: _pulse!,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _CoachPainter(
                        target: widget.target,
                        flowerDiameter: widget.flowerDiameter,
                        t: _pulse!.value,
                      ),
                      size: Size.infinite,
                      child: child,
                    );
                  },
                  child: _tooltipLayer(context),
                ),
        ),
      ),
    );
  }

  /// The dark tooltip bubble, placed above the target (or below when too near
  /// the top) and clamped within the hero width.
  Widget _tooltipLayer(BuildContext context) {
    final l10n = context.l10n;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final above = widget.target.dy > 64;
        final bubble = _CoachTooltip(
          text: l10n.loveTreeCoachTooltip,
          pointDown: above,
        );
        // Position roughly above/below the target; clamp horizontally so the
        // bubble never runs off the edge.
        const bubbleW = 220.0;
        final left = (widget.target.dx - bubbleW / 2).clamp(12.0, w - bubbleW - 12.0);
        final top = above
            ? (widget.target.dy - widget.flowerDiameter / 2 - 56)
            : (widget.target.dy + widget.flowerDiameter / 2 + 12);
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top.clamp(8.0, constraints.maxHeight - 64),
              width: bubbleW,
              child: Align(
                alignment: Alignment.center,
                child: bubble,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The dark tooltip bubble with a little pointer triangle.
class _CoachTooltip extends StatelessWidget {
  const _CoachTooltip({required this.text, required this.pointDown});

  final String text;
  final bool pointDown;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppColors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
    final pointer = CustomPaint(
      size: const Size(10, 7),
      painter: _TooltipPointer(
        color: AppColors.textPrimary.withValues(alpha: 0.92),
        down: pointDown,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: pointDown ? [bubble, pointer] : [pointer, bubble],
    );
  }
}

class _TooltipPointer extends CustomPainter {
  _TooltipPointer({required this.color, required this.down});

  final Color color;
  final bool down;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (down) {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TooltipPointer oldDelegate) =>
      oldDelegate.color != color || oldDelegate.down != down;
}

/// Paints the coach ripple rings + tap-dot around the target flower. [t] is the
/// 1400ms clock phase (0..1) or -1 for the static Reduce-Motion frame.
class _CoachPainter extends CustomPainter {
  _CoachPainter({
    required this.target,
    required this.flowerDiameter,
    required this.t,
  });

  final Offset target;
  final double flowerDiameter;
  final double t;

  bool get _static => t < 0;

  @override
  void paint(Canvas canvas, Size size) {
    final baseR = flowerDiameter * 0.7;

    if (_static) {
      // Reduce Motion: a single steady ring + a calm tap-dot.
      canvas.drawCircle(
        target,
        flowerDiameter * 1.1,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.accentLoveDeep.withValues(alpha: 0.40),
      );
      _paintTapDot(canvas, scale: 1.0);
      return;
    }

    // 3 concentric rings, phase-offset by 0.33, each scaling 0.6→1.8 + fading.
    for (var i = 0; i < 3; i++) {
      final phase = (t + i * 0.33) % 1.0;
      final scale = 0.6 + Curves.easeOut.transform(phase) * 1.2; // 0.6→1.8
      final alpha = (1.0 - phase) * 0.45;
      if (alpha <= 0.01) {
        continue;
      }
      canvas.drawCircle(
        target,
        baseR * scale,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = AppColors.accentLoveDeep.withValues(alpha: alpha),
      );
    }

    // Tap-dot pulse: scale 1.0→0.82→1.0 on a 1s cadence (≈t over the 1.4s clk).
    final tapPhase = (t * 1.4) % 1.0;
    final tapScale = 1.0 - (math.sin(tapPhase * math.pi) * 0.18);
    _paintTapDot(canvas, scale: tapScale);
  }

  /// A "finger tap" dot offset down-right of the flower so it doesn't cover the
  /// nucleus: a white core with an accent ring.
  void _paintTapDot(Canvas canvas, {required double scale}) {
    final c = target.translate(10, 14);
    final r = 9.0 * scale;
    canvas.drawCircle(c, r, Paint()..color = AppColors.white.withValues(alpha: 0.90));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.accentLoveDeep,
    );
  }

  @override
  bool shouldRepaint(_CoachPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.target != target ||
      oldDelegate.flowerDiameter != flowerDiameter;
}

// ───────────────────────────────────────────────────────────────────────────
// Tap-hint caption (v2.1 §B.2) — permanent "tap a flower" affordance
// ───────────────────────────────────────────────────────────────────────────

/// The always-on caption below the tree ("Tap a flower to relive a memory") —
/// a quiet icon + line on the blush background, shown whenever there is ≥1
/// flower. No pill, no animation.
class _TapHintCaption extends StatelessWidget {
  const _TapHintCaption({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(IconsaxPlusLinear.finger_cricle,
            size: 14, color: AppColors.accentRose),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.loveTreeTapHint,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTheme.fontFamily,
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
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
              painter: kTreeRenderer.treePainter(
                stage: LoveTreeStage.green,
                skeleton: true,
              ),
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
  const _BloomBanner({
    required this.count,
    required this.reduceMotion,
    this.onShare,
  });

  final int count;
  final bool reduceMotion;

  /// Opens the share-card flow (v2 #3) — the bloom moment is the best time to
  /// brag, so it doubles as a growth-loop entry.
  final VoidCallback? onShare;

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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(IconsaxPlusLinear.magic_star,
                  size: 16, color: AppColors.accentLoveDeep),
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
          if (onShare != null) ...[
            const SizedBox(height: 10),
            _SharePill(label: l10n.loveTreeShareButton, onTap: onShare!),
          ],
        ],
      ),
    );

    if (reduceMotion) {
      return banner;
    }
    return EntranceReveal(order: 0, child: banner);
  }
}

/// Small rose-tinted "Khoe cây" pill shown inside the bloom banner.
class _SharePill extends StatelessWidget {
  const _SharePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        splashColor: AppColors.accentRose.withValues(alpha: 0.12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.accentRose.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(IconsaxPlusLinear.share,
                  size: 14, color: AppColors.accentLoveDeep),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.accentLoveDeep,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
    required this.anniversary,
    required this.photoProvider,
  });

  final AppLocalizations l10n;
  final List<LoveTreeMilestone> milestones;
  final int days;
  final int longestStreak;
  final int photoCount;
  final DateTime anniversary;
  final PhotoProvider photoProvider;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];

    final reached = milestones.where((m) => m.reached).toList();
    for (final m in reached) {
      rows.add(_MilestoneRow(
        label: _label(m),
        kind: m.kind,
        reached: true,
        onTap: () => _openMomentSheet(
          context,
          m,
          anniversary: anniversary,
          photo: photoProvider,
        ),
      ));
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
          onTap: () => MomentSheet.showLocked(
            context,
            kind: kind,
            value: next.value,
            remaining: _remainingCount(next),
          ),
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
    final n = _remainingCount(m);
    switch (m.kind) {
      case FlowerKind.days:
        return l10n.loveTreeMilestoneDaysLeft(n);
      case FlowerKind.streak:
        return l10n.loveTreeMilestoneStreakLeft(n);
      case FlowerKind.photos:
        return l10n.loveTreeMilestonePhotosLeft(n);
    }
  }

  /// How far the unreached milestone [m] still is (clamped ≥1).
  int _remainingCount(LoveTreeMilestone m) {
    switch (m.kind) {
      case FlowerKind.days:
        return (m.value - days).clamp(1, m.value);
      case FlowerKind.streak:
        return (m.value - longestStreak).clamp(1, m.value);
      case FlowerKind.photos:
        return (m.value - photoCount).clamp(1, m.value);
    }
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({
    required this.label,
    required this.kind,
    required this.reached,
    this.remaining,
    this.onTap,
  });

  final String label;
  final FlowerKind kind;
  final bool reached;
  final String? remaining;

  /// Opens the moment sheet (bloomed) or the locked hint (next).
  final VoidCallback? onTap;

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

    final content = Opacity(opacity: reached ? 1.0 : 0.65, child: row);
    if (onTap == null) {
      return content;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: content,
      ),
    );
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
              painter: kTreeRenderer.treePainter(stage: LoveTreeStage.seed),
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
    this.swayPhase = 0,
    this.ambient,
    this.onTap,
  });

  final FlowerKind kind;
  final double diameter;
  final bool isNew;

  /// Stagger slot among the new flowers (0-based), for the cascading bloom.
  final int bloomOrder;
  final bool reduceMotion;

  /// Per-flower phase offset for the idle sway (design §B.4).
  final double swayPhase;

  /// Shared idle clock (null = no sway, e.g. Reduce Motion / share card).
  final AnimationController? ambient;

  /// Opens the "Khoảnh khắc này" sheet (null = non-interactive, e.g. share card).
  final VoidCallback? onTap;

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
    return _wrapInteractive(_buildSwaying());
  }

  /// Wraps the flower in a 44×44 opaque hit target (design §A.1) so even the
  /// 28px scaled flowers are easy to tap; the visible flower is NOT enlarged.
  Widget _wrapInteractive(Widget flower) {
    if (widget.onTap == null) {
      return flower; // share card — not interactive.
    }
    final pad = _flowerHitPad(widget.diameter);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Padding(
        // The caller offsets the Positioned by `pad` so the flower stays
        // centred on its slot while the touch box grows symmetrically.
        padding: EdgeInsets.all(pad),
        child: flower,
      ),
    );
  }

  /// Adds the gentle idle sway (±2°) once the flower has finished blooming.
  Widget _buildSwaying() {
    final ambient = widget.ambient;
    final base = _buildBloom();
    if (ambient == null || widget.reduceMotion) {
      return base;
    }
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final t = (ambient.value * 2 * math.pi) + widget.swayPhase;
        final angle = math.sin(t) * 0.035; // ±2°
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: base,
    );
  }

  /// The bloom-in animation (new flowers only); otherwise the static flower.
  Widget _buildBloom() {
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

    // Upgraded disc (v2.1 §A.2.2): a radial highlight from the top-left gives
    // the disc a glossy, rounded "enamel" volume. Streak keeps its diagonal
    // gradient but also brightens at the highlight.
    final Gradient gradient = kind == FlowerKind.streak
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _shadeFlowerColor(AppColors.sunset2, 0.10),
              AppColors.accentLoveDeep,
            ],
          )
        : RadialGradient(
            center: const Alignment(-0.3, -0.3),
            radius: 1.0,
            colors: [
              _shadeFlowerColor(color, 0.14),
              color,
              _shadeFlowerColor(color, -0.10),
            ],
            stops: const [0.0, 0.55, 1.0],
          );

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        // Outer white rim (slightly thicker than v1).
        border: Border.all(color: AppColors.white.withValues(alpha: 0.65), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.30),
            blurRadius: 6,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner ring (men-sứ feel) — a faint white circle just inside the rim.
          Container(
            width: diameter - 3,
            height: diameter - 3,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.30),
                width: 0.8,
              ),
            ),
          ),
          // Icon with a subtle inset shadow so it separates from the bright disc.
          Icon(
            LoveTreeService.nucleusIcon(kind),
            size: diameter * 0.6,
            color: AppColors.white,
            shadows: [
              Shadow(
                color: _shadeFlowerColor(color, -0.2).withValues(alpha: 0.35),
                blurRadius: 1.5,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Paints the soft petals of a flower (v2.1 §A.2.1): TWO layers of 6 teardrop
/// petals — an under-layer rotated +30° and scaled 0.86 (filled flat with the
/// edge colour) plus a top layer with a 3-stop radial gradient (a bright
/// near-white centre out to [edgeColor]). A faint drop shadow under the bloom
/// lifts it off the canopy. Geometry (petal length/width relative to [size]) is
/// unchanged from v1 so the flower box stays the same size.
class _FlowerPetalsPainter extends CustomPainter {
  _FlowerPetalsPainter({required this.edgeColor});

  final Color edgeColor;

  static const int _petalCount = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalLen = size.height * 0.46;
    // Slightly fuller belly than v1 (×1.08) for a "plumper" petal.
    final petalW = size.width * 0.30 * 1.08;

    // Drop shadow under the bloom (skip on tiny flowers to keep it clean).
    if (size.width >= 30) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, 2),
          width: size.width * 0.62,
          height: size.height * 0.34,
        ),
        Paint()
          ..color = _shadeFlowerColor(edgeColor, -0.15).withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    // Under-layer: 6 petals tucked between the top ones (+30°), darker + flat.
    final underFill = Paint()..color = edgeColor.withValues(alpha: 0.85);
    for (int i = 0; i < _petalCount; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * (2 * math.pi / _petalCount) + (math.pi / 6)); // +30°
      canvas.scale(0.86);
      canvas.drawPath(_petalPath(size, petalLen, petalW), underFill);
      canvas.restore();
    }

    // Top-layer: 6 petals with a 3-stop radial gradient + a soft fading edge.
    for (int i = 0; i < _petalCount; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * (2 * math.pi / _petalCount));

      final path = _petalPath(size, petalLen, petalW);

      final fill = Paint()
        ..shader = RadialGradient(
          colors: [const Color(0xFFFFF0F4), const Color(0xFFFFD6E0), edgeColor],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset.zero, radius: petalLen),
        );
      canvas.drawPath(path, fill);

      // Edge: white .40 near the base fading to .12 at the tip.
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.white.withValues(alpha: 0.40),
            AppColors.white.withValues(alpha: 0.12),
          ],
        ).createShader(Rect.fromLTWH(-petalW, -petalLen, petalW * 2, petalLen));
      canvas.drawPath(path, stroke);
      canvas.restore();
    }
  }

  /// A teardrop petal pointing up (−y), tip at -[petalLen], with a gentle uplift
  /// near the tip (extra control points) so it reads softly pointed, not sharp.
  Path _petalPath(Size size, double petalLen, double petalW) {
    final baseY = -size.height * 0.05;
    return Path()
      ..moveTo(0, baseY)
      ..cubicTo(
        -petalW, -petalLen * 0.45,
        -petalW * 0.5, -petalLen * 0.92,
        0, -petalLen,
      )
      ..cubicTo(
        petalW * 0.5, -petalLen * 0.92,
        petalW, -petalLen * 0.45,
        0, baseY,
      )
      ..close();
  }

  @override
  bool shouldRepaint(_FlowerPetalsPainter oldDelegate) =>
      oldDelegate.edgeColor != edgeColor;
}

/// Lightness shift for a flower colour (positive = lighten, negative = darken),
/// local to this painter so it doesn't depend on [LoveTreePainter]'s privates.
Color _shadeFlowerColor(Color c, double amt) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amt).clamp(0.0, 1.0)).toColor();
}

// ───────────────────────────────────────────────────────────────────────────
// Render layer boundary (v2.1 §A.3) — "HOW the tree/flowers look", split from
// "WHAT/WHERE/HOW MANY" (milestone math, stage, bloomPositions, canopyGeometry,
// tap → MomentSheet, lastSeen, share) which stay in the screen/service.
//
// Contract a renderer MUST honour so v3 can drop in an SVG/Lottie renderer
// WITHOUT touching the milestone/stage/tap logic:
//   1. paintTree() draws the tree for [stage]/[season] onto the given canvas;
//      it MUST treat LoveTreePainter.canopyGeometry(stage, size) as the source
//      of truth for the canopy centre + radius, since the screen lays flowers
//      out against it (bloomPositions).
//   2. flowerWidget() builds ONE flower inside a [diameter]×[diameter] box, the
//      bloom centred in the box and the nucleus at its centre (so the screen's
//      hit-padding + bloom-pop animation stay correct).
//   3. A renderer NEVER reads providers and NEVER computes milestones — it only
//      receives stage/kind/diameter/season + motion flags.
//
// v2.1 ships a single CustomPaint implementation ([PaintTreeRenderer]); v3 would
// add e.g. AssetTreeRenderer and switch [kTreeRenderer].
// ───────────────────────────────────────────────────────────────────────────

abstract class LoveTreeRenderer {
  const LoveTreeRenderer();

  /// A [CustomPainter] that draws the tree/branch for a stage. [skeleton] paints
  /// a flat grey silhouette; [season] tints the foliage (null = neutral).
  CustomPainter treePainter({
    required LoveTreeStage stage,
    Season? season,
    bool skeleton = false,
  });

  /// Builds one flower inside a [diameter]-square box (centre = nucleus). When
  /// [isNew] + !reduceMotion the caller animates it blooming in; [ambient]
  /// drives the idle sway (null = no sway, e.g. the share card). [onTap] (null =
  /// non-interactive) opens the moment sheet.
  Widget flowerWidget({
    required FlowerKind kind,
    required double diameter,
    required bool isNew,
    required int bloomOrder,
    required bool reduceMotion,
    double swayPhase = 0,
    AnimationController? ambient,
    VoidCallback? onTap,
  });

  /// The DETERMINISTIC positions of [count] flowers (canvas-relative, centre of
  /// each bloom) for a stage on a canvas of [size]. Index `i` is the flower's
  /// stable slot (oldest→newest). Both this and [treePainter] must agree on the
  /// same geometry so flowers land on the foliage / branch they're meant to.
  List<Offset> bloomPositions(LoveTreeStage stage, Size size, int count);

  /// A notional anchor used by the bloom-stage glow / coach fallbacks:
  /// `center` ≈ the visual heart of the foliage, `radius` a soft extent.
  (Offset, double) canopyGeometry(LoveTreeStage stage, Size size);
}

/// The v2.1 CustomPaint implementation: the tree is [LoveTreePainter], a flower
/// is [_LoveFlower] (petals painter + nucleus disc). A v3 asset renderer would
/// implement the same contract.
class PaintTreeRenderer extends LoveTreeRenderer {
  const PaintTreeRenderer();

  @override
  CustomPainter treePainter({
    required LoveTreeStage stage,
    Season? season,
    bool skeleton = false,
  }) =>
      LoveTreePainter(stage: stage, season: season, skeleton: skeleton);

  @override
  Widget flowerWidget({
    required FlowerKind kind,
    required double diameter,
    required bool isNew,
    required int bloomOrder,
    required bool reduceMotion,
    double swayPhase = 0,
    AnimationController? ambient,
    VoidCallback? onTap,
  }) =>
      _LoveFlower(
        kind: kind,
        diameter: diameter,
        isNew: isNew,
        bloomOrder: bloomOrder,
        reduceMotion: reduceMotion,
        swayPhase: swayPhase,
        ambient: ambient,
        onTap: onTap,
      );

  @override
  List<Offset> bloomPositions(LoveTreeStage stage, Size size, int count) =>
      _canopyBloomPositions(stage, size, count);

  @override
  (Offset, double) canopyGeometry(LoveTreeStage stage, Size size) =>
      LoveTreePainter.canopyGeometry(stage, size);
}

/// The active renderer. v2.2 ships the sakura-branch look ([SakuraBranchRenderer]);
/// swap this back to [PaintTreeRenderer] to roll the whole feature back to the
/// v2.1 canopy tree (single-constant rollback), or to an asset renderer at v3.
const LoveTreeRenderer kTreeRenderer = SakuraBranchRenderer();

// ───────────────────────────────────────────────────────────────────────────
// Tree painter — trunk / canopy (blob) / leaves / mound / bokeh per stage
// ───────────────────────────────────────────────────────────────────────────

class LoveTreePainter extends CustomPainter {
  LoveTreePainter({
    required this.stage,
    this.skeleton = false,
    this.season,
  });

  final LoveTreeStage stage;

  /// Season tint over the canopy (v2 #2 §B.3) — null = no tint (loading /
  /// no-couple states, which keep the neutral v1 look).
  final Season? season;

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
    const stemBaseColor = Color(0xFF7BA86A);
    final stemColor = skeleton ? AppColors.surfaceLight : stemBaseColor;
    final stemTop = Offset(base.dx, base.dy - h * 0.12);

    // A small soft shadow where the sprout meets the mound (so it "stands").
    if (!skeleton) {
      canvas.drawOval(
        Rect.fromCenter(
          center: base.translate(0, 1),
          width: 18,
          height: 6,
        ),
        Paint()
          ..color = _darken(stemBaseColor, 0.10).withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

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

    // Two cotyledon leaves at the tip (±32°, 3-stop gradient for volume).
    const leafColors = [Color(0xFFB6E0A0), Color(0xFF8FCB7A), Color(0xFF66A85C)];
    _paintLeaf(canvas, stemTop, h * 0.10, -32, leafColors);
    _paintLeaf(canvas, stemTop, h * 0.10, 32, leafColors);

    // A tiny dew drop on the left leaf.
    final dewAt = Offset(stemTop.dx - h * 0.045, stemTop.dy - h * 0.045);
    canvas.drawCircle(
      dewAt,
      2.5,
      Paint()..color = AppColors.white.withValues(alpha: 0.70),
    );
    canvas.drawCircle(
      dewAt.translate(-0.7, -0.7),
      0.9,
      Paint()..color = AppColors.white.withValues(alpha: 0.95),
    );
  }

  // ── Full tree (S1+) ──────────────────────────────────────────────────────────

  void _paintTree(Canvas canvas, Size size, Offset base) {
    final w = size.width;
    final h = size.height;

    final spec = _specForStage(stage);
    final tH = spec.trunkHeight;
    final trunkTop = Offset(base.dx, base.dy - h * tH);
    final trunkColor = skeleton ? AppColors.surfaceLight : spec.trunkColor;

    // ── Trunk — a "ribbon" with two cubic-bézier edges (v2.1 §A.1.1). The two
    // edges are slightly out of phase (right control nudged +1.5px) so the
    // trunk reads alive, not robotic. Base/top widths come from spec so the
    // overall envelope (and thus the canopy anchor) is unchanged from v1.
    final trunk = Path()
      ..moveTo(base.dx - spec.trunkBase, base.dy)
      ..cubicTo(
        base.dx - spec.trunkBase * 0.55, base.dy - h * tH * 0.35,
        trunkTop.dx - spec.trunkTop * 1.4, base.dy - h * tH * 0.72,
        trunkTop.dx - spec.trunkTop, trunkTop.dy,
      )
      ..lineTo(trunkTop.dx + spec.trunkTop, trunkTop.dy)
      ..cubicTo(
        trunkTop.dx + spec.trunkTop * 1.4 + 1.5, base.dy - h * tH * 0.72,
        base.dx + spec.trunkBase * 0.55 + 1.5, base.dy - h * tH * 0.35,
        base.dx + spec.trunkBase, base.dy,
      )
      ..close();

    if (skeleton) {
      canvas.drawPath(trunk, Paint()..color = trunkColor);
    } else {
      // Horizontal gradient → rounded volume (light left, dark right).
      final trunkFill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            _lighten(trunkColor, 0.06),
            trunkColor,
            _darken(trunkColor, 0.10),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(
          base.dx - spec.trunkBase, trunkTop.dy,
          spec.trunkBase * 2, h * tH,
        ));
      canvas.drawPath(trunk, trunkFill);

      // Bark grain (young+): a faint curved line down the trunk.
      if (spec.canopyR >= 90) {
        final grain = Path()
          ..moveTo(base.dx - spec.trunkBase * 0.2, base.dy - h * tH * 0.08)
          ..cubicTo(
            base.dx + 2, base.dy - h * tH * 0.4,
            base.dx - 2, base.dy - h * tH * 0.65,
            trunkTop.dx, trunkTop.dy + h * tH * 0.06,
          );
        canvas.drawPath(
          grain,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = _darken(trunkColor, 0.12).withValues(alpha: 0.35),
        );
      }
    }

    // ── Branches — tapered spindle paths (FILL, not even stroke) that sag then
    // lift (extra control point) for a natural arc; tip rounded.
    for (final dir in spec.branchDirs) {
      final start = Offset(base.dx, base.dy - h * tH * 0.65);
      final end = Offset(
        base.dx + dir * w * 0.14,
        base.dy - h * tH * 0.92,
      );
      _paintBranch(canvas, start, end, dir, spec.branchWidth, trunkColor, h);
    }

    // Canopy centre — UNCHANGED from v1 (anchor for bloomPositions).
    final canopyCenter = Offset(base.dx, base.dy - h * tH - spec.canopyR * 0.35);
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

    // Canopy drop shadow (S6+) — softer than v1 (alpha .10 / blur 10).
    if (spec.hasShadow && !skeleton) {
      final shadowPath = _blobPath(
        Offset(canopyCenter.dx - 6, canopyCenter.dy + 8),
        canopyR,
        spec.bumps,
      );
      canvas.drawPath(
        shadowPath,
        Paint()
          ..color = const Color(0xFF3D6B33).withValues(alpha: 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // ── Canopy — three layers (back / mid / front) for depth (v2.1 §A.1.2).
    // The MID layer keeps the exact v1 centre + radius + gradient so flowers
    // (which anchor to canopyGeometry) still land on the leaves.
    if (skeleton) {
      // Skeleton keeps the flat v1 grey silhouette (no multi-layer colour).
      canvas.drawPath(_blobPath(canopyCenter, canopyR, spec.bumps),
          Paint()..color = AppColors.surfaceLight);
      return;
    }

    // Back layer (only when the canopy is big enough — keeps sprout light).
    if (canopyR >= 70) {
      final backPath = _blobPath(
        Offset(canopyCenter.dx + canopyR * 0.10, canopyCenter.dy + canopyR * 0.06),
        canopyR * 1.02,
        spec.bumps,
      );
      canvas.drawPath(
        backPath,
        Paint()
          ..color = _darken(spec.canopyDark, 0.10).withValues(alpha: 0.92)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Mid layer (the main, read canopy — IDENTICAL to v1).
    final canopyPath = _blobPath(canopyCenter, canopyR * 0.96, spec.bumps);
    final canopyFill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [spec.canopyLight, spec.canopyDark],
      ).createShader(Rect.fromCircle(center: canopyCenter, radius: canopyR));
    canvas.drawPath(canopyPath, canopyFill);

    // Leaves dotted around the rim — now a 3-stop gradient for volume. Autumn
    // turns a couple of them golden.
    final leafColors = [
      _lighten(spec.canopyDark, 0.06),
      spec.canopyDark,
      _darken(spec.canopyDark, 0.10),
    ];
    const autumnLeaf = [Color(0xFFF0B95A), Color(0xFFE8A33D), Color(0xFFD9822B)];
    for (int i = 0; i < spec.leafCount; i++) {
      final a = i * (2 * math.pi / spec.leafCount) + 0.3;
      final lp = Offset(
        canopyCenter.dx + math.cos(a) * canopyR * 0.92,
        canopyCenter.dy + math.sin(a) * canopyR * 0.62,
      );
      final autumn = season == Season.autumn && i % 4 == 1;
      _paintLeaf(canvas, lp, canopyR * 0.22, a * 180 / math.pi + 90,
          autumn ? autumnLeaf : leafColors);
    }

    // Front highlight (the light source, top-left) — a soft radial bloom.
    final frontCenter =
        Offset(canopyCenter.dx - canopyR * 0.12, canopyCenter.dy - canopyR * 0.10);
    canvas.drawCircle(
      frontCenter,
      canopyR * 0.64,
      Paint()
        ..shader = RadialGradient(
          colors: [
            _lighten(spec.canopyLight, 0.10).withValues(alpha: 0.55),
            _lighten(spec.canopyLight, 0.10).withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: frontCenter, radius: canopyR * 0.64)),
    );

    // Season tint over the canopy (v2 #2 §B.3) — a soft colour wash that keeps
    // the stage geometry but reads as a different time of year.
    _paintSeasonTint(canvas, canopyPath);

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

  /// A tapered branch (v2.1 §A.1.1): a spindle that sags then lifts, thick at
  /// the [start] (≈[width]) and thin at the [end] (≈[width]*0.4). Drawn as a
  /// FILLED outline so the taper reads, with a horizontal gradient for volume.
  void _paintBranch(
    Canvas canvas,
    Offset start,
    Offset end,
    int dir,
    double width,
    Color color,
    double h,
  ) {
    if (width <= 0) {
      return;
    }
    final w0 = width / 2; // half-width at the base
    final w1 = (width * 0.4) / 2; // half-width at the tip
    // Centre curve: sag a touch (down) at the midpoint then arc to the lifted
    // tip — gives a natural droop-then-reach silhouette.
    final ctrl = Offset(
      (start.dx + end.dx) / 2 + dir * 6,
      ((start.dy + end.dy) / 2) + h * 0.012,
    );
    // Perpendicular at the ends to offset the outline.
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    final nx = len == 0 ? 0.0 : -dy / len;
    final ny = len == 0 ? 0.0 : dx / len;

    final path = Path()
      ..moveTo(start.dx + nx * w0, start.dy + ny * w0)
      ..quadraticBezierTo(
        ctrl.dx + nx * (w0 + w1) / 2, ctrl.dy + ny * (w0 + w1) / 2,
        end.dx + nx * w1, end.dy + ny * w1,
      )
      ..lineTo(end.dx - nx * w1, end.dy - ny * w1)
      ..quadraticBezierTo(
        ctrl.dx - nx * (w0 + w1) / 2, ctrl.dy - ny * (w0 + w1) / 2,
        start.dx - nx * w0, start.dy - ny * w0,
      )
      ..close();

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [_lighten(color, 0.05), color, _darken(color, 0.10)],
      ).createShader(Rect.fromPoints(
        Offset(math.min(start.dx, end.dx) - w0, math.min(start.dy, end.dy)),
        Offset(math.max(start.dx, end.dx) + w0, math.max(start.dy, end.dy)),
      ));
    canvas.drawPath(path, fill);
    // Rounded tip cap.
    canvas.drawCircle(end, w1, Paint()..color = _darken(color, 0.06));
  }

  /// A translucent colour wash clipped to the canopy, per season (§B.3):
  /// summer = deep green, winter = cool grey-blue, spring = a touch lighter,
  /// autumn = warm (the golden leaves carry it). Skipped when [season] is null.
  void _paintSeasonTint(Canvas canvas, Path canopyPath) {
    if (season == null || skeleton) {
      return;
    }
    final Color? tint;
    switch (season!) {
      case Season.summer:
        tint = const Color(0xFF3E8E41).withValues(alpha: 0.12);
        break;
      case Season.winter:
        tint = const Color(0xFF5A7A8C).withValues(alpha: 0.10);
        break;
      case Season.spring:
        tint = AppColors.white.withValues(alpha: 0.06);
        break;
      case Season.autumn:
        tint = const Color(0xFFE8A33D).withValues(alpha: 0.06);
        break;
    }
    canvas.drawPath(canopyPath, Paint()..color = tint);
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
  /// gradient (2 or 3 stops — 3 stops give the leaf a little volume) + a thin
  /// white vein.
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

  Color _darken(Color c, [double amt = 0.08]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amt).clamp(0.0, 1.0)).toColor();
  }

  /// Symmetric counterpart of [_darken] (v2.1 §A.1.1) — used by the trunk/canopy
  /// gradients and the multi-layer leaves for highlight stops.
  Color _lighten(Color c, [double amt = 0.08]) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness + amt).clamp(0.0, 1.0)).toColor();
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
      oldDelegate.stage != stage ||
      oldDelegate.skeleton != skeleton ||
      oldDelegate.season != season;
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

// ───────────────────────────────────────────────────────────────────────────
// Sky backdrop (v2 #2 §B.1/B.2) — time-of-day gradient + static stars (night)
// ───────────────────────────────────────────────────────────────────────────

/// The sky layer painted BELOW the tree: a soft top-fading gradient by hour,
/// plus deterministic static stars at night. Always static (kept even under
/// Reduce Motion); repaints only when phase/season/size change.
class SkyBackdropPainter extends CustomPainter {
  SkyBackdropPainter({required this.phase, required this.season});

  final SkyPhase phase;
  final Season season;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Gradient stops per phase (top → bottom → transparent). Only covers ~72%
    // of the area so the mound + bokeh below stay clean.
    final List<Color> colors;
    switch (phase) {
      case SkyPhase.dawn:
        colors = [
          const Color(0xFFFFE3C9).withValues(alpha: 0.55),
          const Color(0xFFFFC9D8).withValues(alpha: 0.45),
          const Color(0x00FFC9D8),
        ];
        break;
      case SkyPhase.day:
        colors = [
          const Color(0xFFCFE9FF).withValues(alpha: 0.40),
          const Color(0xFFFFE0EC).withValues(alpha: 0.30),
          const Color(0x00FFE0EC),
        ];
        break;
      case SkyPhase.dusk:
        colors = [
          const Color(0xFFFF9E7D).withValues(alpha: 0.55),
          const Color(0xFFFF6B9D).withValues(alpha: 0.42),
          const Color(0xFFC8A8E9).withValues(alpha: 0.30),
        ];
        break;
      case SkyPhase.night:
        colors = [
          const Color(0xFF2E2A52).withValues(alpha: 0.78),
          const Color(0xFF4A3D6B).withValues(alpha: 0.62),
          const Color(0xFF6B5A8C).withValues(alpha: 0.40),
        ];
        break;
    }

    final rect = Rect.fromLTWH(0, 0, w, h * 0.78);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    if (phase == SkyPhase.night) {
      _paintStars(canvas, size);
    }
  }

  // 14 deterministic stars in the upper band (fraction x, y, r, alpha).
  static const List<List<double>> _stars = [
    [0.12, 0.10, 2.0, 0.85],
    [0.22, 0.20, 1.2, 0.55],
    [0.34, 0.08, 1.6, 0.70],
    [0.46, 0.15, 1.0, 0.50],
    [0.58, 0.07, 2.2, 0.90],
    [0.68, 0.18, 1.4, 0.65],
    [0.78, 0.10, 1.8, 0.80],
    [0.86, 0.22, 1.1, 0.55],
    [0.16, 0.32, 1.3, 0.60],
    [0.40, 0.30, 1.0, 0.50],
    [0.62, 0.34, 1.5, 0.70],
    [0.74, 0.40, 1.2, 0.55],
    [0.30, 0.42, 1.4, 0.60],
    [0.88, 0.36, 1.0, 0.50],
  ];

  void _paintStars(Canvas canvas, Size size) {
    for (var i = 0; i < _stars.length; i++) {
      final s = _stars[i];
      final c = Offset(size.width * s[0], size.height * s[1]);
      final paint = Paint()..color = AppColors.white.withValues(alpha: s[3]);
      canvas.drawCircle(c, s[2], paint);
      // A few brighter stars get a tiny "+" sparkle.
      if (s[2] >= 1.8) {
        final cross = Paint()
          ..color = AppColors.white.withValues(alpha: 0.70)
          ..strokeWidth = 0.8;
        canvas.drawLine(c.translate(-3, 0), c.translate(3, 0), cross);
        canvas.drawLine(c.translate(0, -3), c.translate(0, 3), cross);
      }
    }
  }

  @override
  bool shouldRepaint(SkyBackdropPainter oldDelegate) =>
      oldDelegate.phase != phase || oldDelegate.season != season;
}

// ───────────────────────────────────────────────────────────────────────────
// Ambient idle particles (v2 #2 §B.2/B.3/B.4) — fireflies / falling petals
// ───────────────────────────────────────────────────────────────────────────

/// Idle particles overlaid on the tree: fireflies at night, falling petals
/// (spring) / leaves (autumn) otherwise, capped at ≤9 (design §B.6). Driven by
/// one shared [ambient] clock. Under Reduce Motion the particles are drawn
/// STATIC (fireflies at rest, petals scattered on the mound) — never blank.
class _AmbientParticles extends StatelessWidget {
  const _AmbientParticles({
    required this.phase,
    required this.season,
    required this.reduceMotion,
    required this.ambient,
  });

  final SkyPhase phase;
  final Season season;
  final bool reduceMotion;
  final AnimationController? ambient;

  bool get _fireflies => phase == SkyPhase.night;
  bool get _falling =>
      !_fireflies && (season == Season.spring || season == Season.autumn);

  @override
  Widget build(BuildContext context) {
    if (!_fireflies && !_falling) {
      return const SizedBox.shrink();
    }
    final painter = _ParticlesPainter(
      phase: phase,
      season: season,
      fireflies: _fireflies,
      // t = clock phase; -1 marks the static (Reduce Motion) frame.
      t: -1,
    );

    if (reduceMotion || ambient == null) {
      return CustomPaint(painter: painter, size: Size.infinite);
    }
    return AnimatedBuilder(
      animation: ambient!,
      builder: (context, _) {
        return CustomPaint(
          painter: _ParticlesPainter(
            phase: phase,
            season: season,
            fireflies: _fireflies,
            t: ambient!.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({
    required this.phase,
    required this.season,
    required this.fireflies,
    required this.t,
  });

  final SkyPhase phase;
  final Season season;
  final bool fireflies;

  /// Clock phase 0..1, or -1 for the static Reduce-Motion frame.
  final double t;

  bool get _static => t < 0;

  @override
  void paint(Canvas canvas, Size size) {
    if (fireflies) {
      _paintFireflies(canvas, size);
    } else {
      _paintFalling(canvas, size);
    }
  }

  void _paintFireflies(Canvas canvas, Size size) {
    const count = 5;
    // Anchor positions (fractions) around + below the canopy.
    const anchors = <List<double>>[
      [0.28, 0.30],
      [0.52, 0.22],
      [0.70, 0.34],
      [0.40, 0.46],
      [0.62, 0.50],
    ];
    final core = Paint()..color = const Color(0xFFFFF6C8);
    for (var i = 0; i < count; i++) {
      final ax = anchors[i][0];
      final ay = anchors[i][1];
      double dx = 0;
      double dy = 0;
      double alpha = 0.70;
      if (!_static) {
        // Slow Lissajous drift + breathing alpha, phase-offset per index.
        final phase = t * 2 * math.pi + i * 1.3;
        dx = math.sin(phase) * 14;
        dy = math.cos(phase * 0.7 + i) * 12;
        final breathe = (math.sin(phase * 1.6 + i * 0.9) + 1) / 2; // 0..1
        alpha = 0.25 + breathe * 0.70;
      }
      final c = Offset(size.width * ax + dx, size.height * ay + dy);
      // Glow.
      canvas.drawCircle(
        c,
        4,
        Paint()
          ..color = const Color(0xFFFFE066).withValues(alpha: alpha * 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(c, 1.6, core..color = const Color(0xFFFFF6C8).withValues(alpha: alpha));
    }
  }

  void _paintFalling(Canvas canvas, Size size) {
    const count = 4;
    final spring = season == Season.spring;
    // Falling sakura petals (v2.2 §C.6): soft pink in spring, a warmer amber
    // tinge in autumn (keeps the four seasons distinguishable). Each petal is
    // a small notched sakura petal, not a teardrop leaf.
    final petalColor = spring ? const Color(0xFFFF8FA3) : const Color(0xFFF0B95A);
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFD6E0), petalColor],
      ).createShader(const Rect.fromLTWH(-6, -10, 12, 12));
    for (var i = 0; i < count; i++) {
      final xBase = (0.30 + i * 0.16) % 1.0;
      double progress;
      double swayX;
      double rot;
      if (_static) {
        // Scattered around the branch foot (like fallen petals) — calm frame.
        progress = 0.82 + (i % 2) * 0.06;
        swayX = (i.isEven ? -1 : 1) * 0.04;
        rot = i * 0.9;
      } else {
        // Falls from the upper area (y .15) down (y .88), looping, phase-offset.
        progress = ((t + i / count) % 1.0);
        // Petals flutter side to side a touch more than leaves did.
        swayX = math.sin((progress * 2 * math.pi) + i) * 0.06;
        rot = progress * 4 + i; // gentle tumble
      }
      final x = size.width * (xBase + swayX);
      final y = size.height * (0.15 + progress * 0.73);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      // A small single sakura petal (~10px) with a soft V-notch tip.
      canvas.drawPath(_sakuraPetalPath(10.0), fill);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.fireflies != fireflies ||
      oldDelegate.season != season ||
      oldDelegate.phase != phase;
}

// ───────────────────────────────────────────────────────────────────────────
// Share card (v2 #3) — a self-contained 4:5 branded card rendered off-screen
// ───────────────────────────────────────────────────────────────────────────

/// Immutable data the off-screen [LoveTreeShareCard] needs (so the share flow
/// can capture it without touching providers mid-render).
class _ShareCardData {
  const _ShareCardData({
    required this.stage,
    required this.reached,
    required this.person1Name,
    required this.person2Name,
    required this.creatorUserId,
    required this.statsLine,
    required this.tagline,
  });

  final LoveTreeStage stage;
  final List<LoveTreeMilestone> reached;
  final String person1Name;
  final String person2Name;
  final String creatorUserId;
  final String statsLine;
  final String tagline;
}

/// The branded "Khoe cây" card — a 4:5 portrait built entirely from the same
/// [LoveTreePainter] + flower widgets, on a sunset gradient, with the couple
/// name, stats, tagline and a "Dear Embeiu" watermark. Self-contained: no
/// dependency on the screen layout, so it can be rendered off-screen → PNG.
class _LoveTreeShareCard extends StatelessWidget {
  const _LoveTreeShareCard({
    required this.width,
    required this.data,
  });

  /// Logical width; height is width * 5/4 (4:5 portrait).
  final double width;
  final _ShareCardData data;

  @override
  Widget build(BuildContext context) {
    final height = width * 5 / 4;
    // The tree occupies the middle band (y 16%→62%).
    final treeHeight = height * 0.46;
    final treeTop = height * 0.16;

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.sunset1, AppColors.sunset2, AppColors.sunset3],
          ),
        ),
        child: Stack(
          children: [
            // Soft radial glow behind the tree for depth.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.25),
                    radius: 0.9,
                    colors: [
                      AppColors.white.withValues(alpha: 0.14),
                      AppColors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            // Tree (stage + flowers) — reuses the painter + flower layout.
            Positioned(
              left: 0,
              right: 0,
              top: treeTop,
              height: treeHeight,
              child: _ShareTree(stage: data.stage, reached: data.reached),
            ),

            // Couple name + stats + tagline + watermark.
            Positioned(
              left: width * 0.08,
              right: width * 0.08,
              top: height * 0.66,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedCoupleName(
                    person1Name: data.person1Name,
                    person2Name: data.person2Name,
                    pulseHeart: false,
                    alignment: WrapAlignment.center,
                    heartSize: 22,
                    heartColor: AppColors.white,
                    textStyle: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppColors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.statsLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppColors.white.withValues(alpha: 0.92),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    data.tagline,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: AppColors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Watermark (acquisition channel) — bottom-centred.
            Positioned(
              left: 0,
              right: 0,
              bottom: height * 0.04,
              child: Text(
                'Dear Embeiu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppColors.white.withValues(alpha: 0.55),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The static tree (painter + non-interactive flowers) used by the share card.
class _ShareTree extends StatelessWidget {
  const _ShareTree({required this.stage, required this.reached});

  final LoveTreeStage stage;
  final List<LoveTreeMilestone> reached;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final positions = bloomPositions(stage, size, reached.length);
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(painter: kTreeRenderer.treePainter(stage: stage)),
            ),
            for (int i = 0; i < reached.length; i++)
              Positioned(
                left: positions[i].dx - _flowerRadius(i, reached.length),
                top: positions[i].dy - _flowerRadius(i, reached.length),
                child: kTreeRenderer.flowerWidget(
                  kind: reached[i].kind,
                  diameter: _flowerDiameter(i, reached.length),
                  isNew: false,
                  bloomOrder: 0,
                  reduceMotion: true, // fully static for capture
                ),
              ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SAKURA BRANCH (v2.2) — pivot from the canopy tree to a single leaning cherry
// branch whose blossoms ARE the milestones. The metaphor / milestone math /
// stage thresholds / tap → MomentSheet / lastSeen / share are all UNCHANGED;
// this is purely a new RENDER (a [SakuraBranchRenderer] swapped in at
// [kTreeRenderer]). [PaintTreeRenderer] above is kept for a one-constant
// rollback.
// ═════════════════════════════════════════════════════════════════════════════

/// A single sakura petal pointing up (−y), its base at the origin and tip at
/// `(0, -len)` with a soft V-notch — the signature cherry-blossom petal. Used
/// both inside a blossom (5 of them) and as a falling ambient petal.
Path _sakuraPetalPath(double len) {
  final w = len * 0.46; // petal half-width
  final notch = len * 0.16; // shallow V-notch depth at the tip
  return Path()
    ..moveTo(0, -len * 0.06) // stalk tucked slightly into the centre
    ..cubicTo(-w, -len * 0.42, -w * 0.62, -len * 0.86, -w * 0.30, -len)
    // V-notch: dip toward the centre then rise to the right shoulder.
    ..quadraticBezierTo(0, -len + notch, w * 0.30, -len)
    ..cubicTo(w * 0.62, -len * 0.86, w, -len * 0.42, 0, -len * 0.06)
    ..close();
}

// ── Per-stage branch parameters (design §A.4 `_BranchSpec`) ──────────────────

/// One side branch: where it forks off the main branch ([tBranch] ∈ [0,1]), a
/// coarse direction and how long it is relative to the main branch.
class _SideBranch {
  const _SideBranch(this.tBranch, this.dir, this.lenFrac);

  /// Fork position along the main branch (0 = foot, 1 = tip).
  final double tBranch;

  /// Coarse aim: where the tip lands, as fractions of (w, h).
  final Offset dir;

  /// Length as a fraction of the main branch length (informational).
  final double lenFrac;
}

/// Geometry + colour table for one sakura stage (design §A.4). [tEnd] clips the
/// main bézier; [wBase]/[wTip] taper its width; bark darkens/warms by stage.
class _BranchSpec {
  const _BranchSpec({
    required this.tEnd,
    required this.wBase,
    required this.wTip,
    required this.bark,
    required this.sides,
    required this.budCount,
    required this.leafCount,
  });

  final double tEnd;
  final double wBase;
  final double wTip;
  final Color bark;
  final List<_SideBranch> sides;
  final int budCount;
  final int leafCount;
}

_BranchSpec _branchSpecForStage(LoveTreeStage stage) {
  switch (stage) {
    case LoveTreeStage.seed:
      return const _BranchSpec(
        tEnd: 0.34,
        wBase: 5,
        wTip: 2.5,
        bark: Color(0xFFA8755C),
        sides: [],
        budCount: 2,
        leafCount: 0,
      );
    case LoveTreeStage.sprout:
      return const _BranchSpec(
        tEnd: 0.52,
        wBase: 7,
        wTip: 3,
        bark: Color(0xFF9C6A50),
        sides: [],
        budCount: 1,
        leafCount: 0,
      );
    case LoveTreeStage.young:
      return const _BranchSpec(
        tEnd: 0.74,
        wBase: 9,
        wTip: 3.5,
        bark: Color(0xFF8A5A44),
        sides: [_SideBranch(0.42, Offset(0.30, 0.40), 0.26)],
        budCount: 1,
        leafCount: 0,
      );
    case LoveTreeStage.green:
      return const _BranchSpec(
        tEnd: 0.90,
        wBase: 11,
        wTip: 4,
        bark: Color(0xFF7E5039),
        sides: [
          _SideBranch(0.42, Offset(0.30, 0.40), 0.26),
          _SideBranch(0.66, Offset(0.90, 0.34), 0.22),
        ],
        budCount: 1,
        leafCount: 2,
      );
    case LoveTreeStage.bloom:
      return const _BranchSpec(
        tEnd: 1.00,
        wBase: 13,
        wTip: 4.5,
        bark: Color(0xFF724631),
        sides: [
          _SideBranch(0.42, Offset(0.30, 0.40), 0.26),
          _SideBranch(0.66, Offset(0.90, 0.34), 0.22),
          _SideBranch(0.30, Offset(0.50, 0.58), 0.16),
        ],
        budCount: 1,
        leafCount: 3,
      );
  }
}

/// A blossom-bearing curve (the main branch clipped to [tEnd], or a side
/// branch). Exposes [pointAt]/[normalAt]/[wHalf] in canvas px so the painter
/// (which draws it) and [_sakuraBloomPositions] (which anchors blossoms to its
/// edge) share ONE source of truth — blossoms never "miss" the branch.
class _BranchSegment {
  _BranchSegment({
    required this.p0,
    required this.c1,
    required this.c2,
    required this.p3,
    required this.wBaseHalf,
    required this.wTipHalf,
  }) {
    // Sample arc-length so blossom slots spread evenly along the visible curve.
    _length = _measureLength();
  }

  final Offset p0;
  final Offset c1;
  final Offset c2;
  final Offset p3;

  /// Half-width at the segment's start / end (px). The main branch tapers the
  /// whole spec width; a side branch is thinner.
  final double wBaseHalf;
  final double wTipHalf;

  late final double _length;
  double get length => _length;

  /// Point on the cubic bézier at parameter [t] ∈ [0,1].
  Offset pointAt(double t) {
    final mt = 1 - t;
    final a = mt * mt * mt;
    final b = 3 * mt * mt * t;
    final c = 3 * mt * t * t;
    final d = t * t * t;
    return Offset(
      a * p0.dx + b * c1.dx + c * c2.dx + d * p3.dx,
      a * p0.dy + b * c1.dy + c * c2.dy + d * p3.dy,
    );
  }

  /// Unit tangent at [t] (derivative of the cubic, normalised).
  Offset tangentAt(double t) {
    final mt = 1 - t;
    final dx = 3 * mt * mt * (c1.dx - p0.dx) +
        6 * mt * t * (c2.dx - c1.dx) +
        3 * t * t * (p3.dx - c2.dx);
    final dy = 3 * mt * mt * (c1.dy - p0.dy) +
        6 * mt * t * (c2.dy - c1.dy) +
        3 * t * t * (p3.dy - c2.dy);
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 1e-6) {
      return const Offset(0, -1);
    }
    return Offset(dx / len, dy / len);
  }

  /// Unit normal (perpendicular to the tangent) at [t].
  Offset normalAt(double t) {
    final tan = tangentAt(t);
    return Offset(-tan.dy, tan.dx);
  }

  /// Half the branch width at [t] (px) — tapers base→tip with an ease so the
  /// tip thins out faster (a delicate sakura twig).
  double wHalf(double t) {
    final e = Curves.easeIn.transform(t.clamp(0.0, 1.0));
    return wBaseHalf + (wTipHalf - wBaseHalf) * e;
  }

  double _measureLength() {
    var len = 0.0;
    var prev = pointAt(0);
    for (var i = 1; i <= 16; i++) {
      final p = pointAt(i / 16);
      len += (p - prev).distance;
      prev = p;
    }
    return len;
  }

  /// The filled, tapered outline of this branch (FILL, not an even stroke) —
  /// 14 samples down each edge, pushed ±wHalf along the normal, joined + closed.
  Path outlinePath() {
    const samples = 14;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      final p = pointAt(t);
      final n = normalAt(t);
      final hw = wHalf(t);
      left.add(p + n * hw);
      right.add(p - n * hw);
    }
    final path = Path()..moveTo(left.first.dx, left.first.dy);
    for (var i = 1; i < left.length; i++) {
      path.lineTo(left[i].dx, left[i].dy);
    }
    for (var i = right.length - 1; i >= 0; i--) {
      path.lineTo(right[i].dx, right[i].dy);
    }
    path.close();
    return path;
  }
}

/// The single source of truth for the sakura branch geometry at a [stage] on a
/// canvas of [size]: the main branch (clipped to [tEnd]) plus the stage's side
/// branches. Used by BOTH [SakuraBranchPainter] (to draw) and
/// [_sakuraBloomPositions] (to anchor blossoms) so they never disagree.
class _SakuraBranchGeometry {
  _SakuraBranchGeometry(this.stage, this.size) {
    final spec = _branchSpecForStage(stage);
    final w = size.width;
    final h = size.height;

    // Main branch: a soft S-curve from the bottom-left foot up to the right.
    // Control points are fractions of (w, h) per design §A.1.
    final p0 = Offset(w * 0.16, h * 0.96);
    final c1 = Offset(w * 0.30, h * 0.66);
    final c2 = Offset(w * 0.42, h * 0.30);
    final p3Full = Offset(w * 0.74, h * 0.20);
    tEnd = spec.tEnd;

    // Clip the full bézier to [0, tEnd] (de Casteljau) so shorter stages are a
    // genuine sub-curve of the same branch — the tip lands where §A.3 expects.
    final clipped = _subBezier(p0, c1, c2, p3Full, spec.tEnd);
    final main = _BranchSegment(
      p0: clipped[0],
      c1: clipped[1],
      c2: clipped[2],
      p3: clipped[3],
      wBaseHalf: spec.wBase / 2,
      wTipHalf: spec.wTip / 2,
    );
    mainSegment = main;
    tipPoint = main.pointAt(1.0);

    final segs = <_BranchSegment>[main];
    for (final side in spec.sides) {
      // Fork point + width on the main branch.
      final tb = (side.tBranch / spec.tEnd).clamp(0.0, 1.0);
      final start = main.pointAt(tb);
      final forkHalf = main.wHalf(tb) * 0.5;
      final end = Offset(w * side.dir.dx, h * side.dir.dy);
      // Control points bow the side branch upward in the same "spirit" as the
      // main branch (no harsh sideways/downward kinks).
      final ctrl1 = Offset(
        start.dx + (end.dx - start.dx) * 0.35,
        start.dy + (end.dy - start.dy) * 0.25 - h * 0.04,
      );
      final ctrl2 = Offset(
        start.dx + (end.dx - start.dx) * 0.70,
        start.dy + (end.dy - start.dy) * 0.70 - h * 0.02,
      );
      segs.add(_BranchSegment(
        p0: start,
        c1: ctrl1,
        c2: ctrl2,
        p3: end,
        wBaseHalf: forkHalf,
        wTipHalf: spec.wTip * 0.7 / 2,
      ));
    }
    segments = segs;
  }

  final LoveTreeStage stage;
  final Size size;

  late final double tEnd;
  late final _BranchSegment mainSegment;

  /// All blossom-bearing segments: main first, then side branches.
  late final List<_BranchSegment> segments;

  /// The main branch tip — the emotional centre (coach + bloom glow anchor).
  late final Offset tipPoint;
}

/// Splits a cubic bézier at [t], returning the [P0, C1, C2, P3] of the
/// sub-curve over [0, t] (de Casteljau).
List<Offset> _subBezier(Offset p0, Offset c1, Offset c2, Offset p3, double t) {
  Offset lerp(Offset a, Offset b) =>
      Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
  final ab = lerp(p0, c1);
  final bc = lerp(c1, c2);
  final cd = lerp(c2, p3);
  final abc = lerp(ab, bc);
  final bcd = lerp(bc, cd);
  final abcd = lerp(abc, bcd);
  return [p0, ab, abc, abcd];
}

/// Anchors [count] blossoms ALONG the branch (design §B.1): distributes them
/// across the segments by length, spreads each along its segment, then offsets
/// perpendicular to the branch (alternating sides) so the blossom sits right at
/// the branch edge. Fully DETERMINISTIC via [_bloomHash] — no [math.Random], so
/// blossoms never shuffle between builds (AC #3). Clamped inside the canvas.
List<Offset> _sakuraBloomPositions(LoveTreeStage stage, Size size, int count) {
  if (count == 0) {
    return const [];
  }
  final geo = _SakuraBranchGeometry(stage, size);
  final segs = geo.segments;

  // Distribute blossoms across segments weighted by length (the long main
  // branch carries more than a short side branch). At least 1 per non-empty
  // bucket is implied by the round-robin assignment below.
  final totalLen = segs.fold<double>(0, (a, s) => a + s.length);
  final perSeg = List<int>.filled(segs.length, 0);
  if (totalLen <= 0) {
    perSeg[0] = count;
  } else {
    var assigned = 0;
    for (var s = 0; s < segs.length; s++) {
      final share = (count * segs[s].length / totalLen).floor();
      perSeg[s] = share;
      assigned += share;
    }
    // Hand out the remainder to the longest segments first (the main branch).
    var r = count - assigned;
    final order = List<int>.generate(segs.length, (i) => i)
      ..sort((a, b) => segs[b].length.compareTo(segs[a].length));
    var oi = 0;
    while (r > 0) {
      perSeg[order[oi % segs.length]]++;
      oi++;
      r--;
    }
  }

  final out = List<Offset>.filled(count, Offset.zero);

  // Global flower index walks 0..count-1; lower indices (older milestones) sit
  // toward the foot, higher indices toward the tip — "new blooms at the tip".
  var gi = 0;
  for (var s = 0; s < segs.length; s++) {
    final seg = segs[s];
    final n = perSeg[s];
    if (n <= 0) {
      continue;
    }
    // Blossoms live on the upper portion of each segment (leave the woody foot
    // bare): main branch tLo .18, side branches start a touch further out.
    final tLo = s == 0 ? 0.18 : 0.30;
    const tHi = 0.96;
    for (var j = 0; j < n; j++) {
      final i = gi++; // stable global index
      final base = _lerpDouble(tLo, tHi, (j + 0.5) / n);
      // Deterministic ±0.04 jitter along the curve.
      final t = (base + ((_bloomHash(i) % 9) - 4) / 100.0).clamp(0.06, 0.96);
      final p = seg.pointAt(t);
      final nrm = seg.normalAt(t);
      final flowerR = _flowerRadius(i, count);
      final sideSign = (_bloomHash(i * 7 + 3) & 1) == 0 ? 1.0 : -1.0;
      // Sit just off the branch edge + a small deterministic jitter.
      final offsetMag =
          seg.wHalf(t) + flowerR * 0.55 + (_bloomHash(i * 31 + 5) % 6).toDouble();
      var pos = p + nrm * (sideSign * offsetMag);
      // Clamp inside the canvas with a margin so no blossom clips out (§B.1).
      final margin = flowerR + 4;
      pos = Offset(
        pos.dx.clamp(margin, size.width - margin),
        pos.dy.clamp(margin, size.height - margin),
      );
      out[i] = pos;
    }
  }

  // Any leftover (rounding) indices fall back near the tip so they're never
  // left at Offset.zero — shouldn't happen, but defensive.
  for (var i = gi; i < count; i++) {
    final flowerR = _flowerRadius(i, count);
    final margin = flowerR + 4;
    final p = geo.tipPoint;
    out[i] = Offset(
      p.dx.clamp(margin, size.width - margin),
      p.dy.clamp(margin, size.height - margin),
    );
  }

  // Anti-overlap pass (design §I.5): blossoms alternating along the branch can
  // land close enough for their hit-boxes to overlap and cause a mis-tap. Nudge
  // any blossom that sits < 36px from an already-placed one straight away from
  // it. Deterministic (depends only on the deterministic positions above), so
  // it never shuffles between builds. One pass is plenty for the realistic
  // counts (≤18 blossoms).
  const minGap = 36.0;
  for (var i = 1; i < count; i++) {
    final flowerR = _flowerRadius(i, count);
    final margin = flowerR + 4;
    for (var j = 0; j < i; j++) {
      var delta = out[i] - out[j];
      var dist = delta.distance;
      if (dist >= minGap) {
        continue;
      }
      // Push straight away from the neighbour (use a stable fallback direction
      // when the two coincide exactly).
      if (dist < 0.5) {
        delta = ((_bloomHash(i * 17 + 9) & 1) == 0)
            ? const Offset(1, 0)
            : const Offset(0, 1);
        dist = 1.0;
      }
      final dir = delta / dist;
      out[i] = out[i] + dir * (minGap - dist);
      out[i] = Offset(
        out[i].dx.clamp(margin, size.width - margin),
        out[i].dy.clamp(margin, size.height - margin),
      );
    }
  }

  return out;
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

// ── Sakura branch painter (branch + buds + sparse leaves; NO blossoms) ───────

/// Draws the sakura branch (main + side branches), the closed buds and the very
/// sparse accent leaves for a [stage]. Blossoms are NOT drawn here — they are
/// overlay widgets anchored by [_sakuraBloomPositions]. [skeleton] paints a flat
/// grey branch (loading silhouette). Repaints only when stage/season/skeleton
/// change.
class SakuraBranchPainter extends CustomPainter {
  SakuraBranchPainter({
    required this.stage,
    this.season,
    this.skeleton = false,
  });

  final LoveTreeStage stage;
  final Season? season;
  final bool skeleton;

  @override
  void paint(Canvas canvas, Size size) {
    final spec = _branchSpecForStage(stage);
    final geo = _SakuraBranchGeometry(stage, size);

    // Bloom-stage glow behind the tip cluster (skipped on skeleton).
    if (stage == LoveTreeStage.bloom && !skeleton) {
      final r = math.min(size.width, size.height) * 0.30;
      canvas.drawCircle(
        geo.tipPoint,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [
              AppColors.accentRose.withValues(alpha: 0.10),
              AppColors.accentRose.withValues(alpha: 0.0),
            ],
          ).createShader(Rect.fromCircle(center: geo.tipPoint, radius: r)),
      );
    }

    // Draw side branches first so the main branch overlaps their forks cleanly.
    for (var s = geo.segments.length - 1; s >= 1; s--) {
      _paintBranchSegment(canvas, geo.segments[s], spec.bark);
    }
    _paintBranchSegment(canvas, geo.mainSegment, spec.bark, isMain: true);

    if (skeleton) {
      return;
    }

    // Sparse accent leaves (green+) near the foot of the side branches.
    _paintLeaves(canvas, size, geo, spec);

    // Closed buds at / near the tip (the only "flower" at seed stage).
    _paintBuds(canvas, geo, spec);
  }

  void _paintBranchSegment(
    Canvas canvas,
    _BranchSegment seg,
    Color bark, {
    bool isMain = false,
  }) {
    final path = seg.outlinePath();
    if (skeleton) {
      canvas.drawPath(path, Paint()..color = AppColors.surfaceLight);
      return;
    }
    // Volume: a gradient perpendicular to the branch (light edge → dark edge).
    final bounds = path.getBounds();
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _shadeFlowerColor(bark, 0.07),
          bark,
          _shadeFlowerColor(bark, -0.12),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(bounds);
    canvas.drawPath(path, fill);

    // Round the tip so the branch doesn't end in a flat cut.
    final tip = seg.pointAt(1.0);
    canvas.drawCircle(tip, seg.wHalf(1.0), Paint()..color = _shadeFlowerColor(bark, -0.06));

    // Bark grain on the main branch from young+ (a faint curved line on the
    // lower half) — only when the branch is wide enough to read.
    if (isMain && seg.wBaseHalf >= 4.5) {
      final grain = Path()
        ..moveTo(seg.pointAt(0.10).dx, seg.pointAt(0.10).dy)
        ..quadraticBezierTo(
          seg.pointAt(0.30).dx, seg.pointAt(0.30).dy,
          seg.pointAt(0.50).dx, seg.pointAt(0.50).dy,
        );
      canvas.drawPath(
        grain,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = _shadeFlowerColor(bark, -0.14).withValues(alpha: 0.30),
      );
    }
  }

  /// A few sakura accent leaves (green/bloom only) — soft green-into-pink, very
  /// sparse, placed near the side-branch forks so they don't crowd blossoms.
  void _paintLeaves(
    Canvas canvas,
    Size size,
    _SakuraBranchGeometry geo,
    _BranchSpec spec,
  ) {
    if (spec.leafCount <= 0) {
      return;
    }
    const leafColors = [Color(0xFFB8CBA0), Color(0xFF9FBF7A), Color(0xFFC9A8B0)];
    final len = size.height * 0.05;
    // Anchor leaves at deterministic spots along the main branch's lower half.
    final main = geo.mainSegment;
    for (var i = 0; i < spec.leafCount; i++) {
      final t = 0.28 + i * 0.16;
      if (t > 0.92) {
        break;
      }
      final p = main.pointAt(t);
      final n = main.normalAt(t);
      final side = i.isEven ? 1.0 : -1.0;
      final at = p + n * (main.wHalf(t) + len * 0.4) * side;
      final angle = (i.isEven ? 35.0 : -35.0) + i * 10;
      _paintSakuraLeaf(canvas, at, len, angle, leafColors);
    }
  }

  void _paintSakuraLeaf(
    Canvas canvas,
    Offset at,
    double len,
    double angleDeg,
    List<Color> colors,
  ) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angleDeg * math.pi / 180);
    final wdt = len * 0.5;
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
    canvas.drawLine(
      const Offset(0, 0),
      Offset(0, -len * 0.9),
      Paint()
        ..strokeWidth = 0.7
        ..color = AppColors.white.withValues(alpha: 0.18),
    );
    canvas.restore();
  }

  /// Closed pink buds near the tip — the dreamy "about to bloom" accent. At seed
  /// stage these stand in for blossoms; later one sits at the tip.
  void _paintBuds(
    Canvas canvas,
    _SakuraBranchGeometry geo,
    _BranchSpec spec,
  ) {
    final main = geo.mainSegment;
    for (var i = 0; i < spec.budCount; i++) {
      // Buds cluster at the tip; for 2 buds, spread them just below it.
      final t = spec.budCount == 1 ? 0.98 : (0.86 + i * 0.10);
      final p = main.pointAt(t.clamp(0.0, 1.0));
      final n = main.normalAt(t.clamp(0.0, 1.0));
      final side = i.isEven ? 1.0 : -1.0;
      final at = p + n * (main.wHalf(t.clamp(0.0, 1.0)) + 4) * side;
      _paintBud(canvas, at, main.tangentAt(t.clamp(0.0, 1.0)), spec.bark);
    }
  }

  void _paintBud(Canvas canvas, Offset at, Offset tangent, Color bark) {
    // Short stalk linking the bud to the branch.
    final stalkEnd = at;
    final stalkStart = at - tangent * 6;
    canvas.drawLine(
      stalkStart,
      stalkEnd,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..color = bark,
    );

    canvas.save();
    canvas.translate(at.dx, at.dy);
    // Calyx (sepals) hugging the base — soft green, never harsh lime.
    final calyx = Paint()..color = const Color(0xFF9FBF7A);
    canvas.drawCircle(const Offset(0, 1), 3.2, calyx);
    // The bud body: an upright oval, pink-light → pink-deep.
    final budRect = Rect.fromCenter(center: const Offset(0, -4), width: 8, height: 11);
    canvas.drawOval(
      budRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0xFFFF8FA3), Color(0xFFFFD6E0)],
        ).createShader(budRect),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SakuraBranchPainter oldDelegate) =>
      oldDelegate.stage != stage ||
      oldDelegate.season != season ||
      oldDelegate.skeleton != skeleton;
}

// ── Sakura blossom widget (5 notched petals + golden-stamen nucleus) ─────────

/// A sakura blossom — same external contract as [_LoveFlower] (diameter box,
/// nucleus centred, bloom-in animation, idle sway, ≥44px hit-pad) so the screen
/// logic is untouched; only the petals + nucleus look different (§C.1/C.2).
class _SakuraFlower extends StatefulWidget {
  const _SakuraFlower({
    required this.kind,
    required this.diameter,
    required this.isNew,
    required this.bloomOrder,
    required this.reduceMotion,
    this.swayPhase = 0,
    this.ambient,
    this.onTap,
  });

  final FlowerKind kind;
  final double diameter;
  final bool isNew;
  final int bloomOrder;
  final bool reduceMotion;
  final double swayPhase;
  final AnimationController? ambient;
  final VoidCallback? onTap;

  @override
  State<_SakuraFlower> createState() => _SakuraFlowerState();
}

class _SakuraFlowerState extends State<_SakuraFlower>
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
  Widget build(BuildContext context) => _wrapInteractive(_buildSwaying());

  Widget _wrapInteractive(Widget flower) {
    if (widget.onTap == null) {
      return flower; // share card — not interactive.
    }
    final pad = _flowerHitPad(widget.diameter);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Padding(padding: EdgeInsets.all(pad), child: flower),
    );
  }

  Widget _buildSwaying() {
    final ambient = widget.ambient;
    final base = _buildBloom();
    if (ambient == null || widget.reduceMotion) {
      return base;
    }
    return AnimatedBuilder(
      animation: ambient,
      builder: (context, child) {
        final t = (ambient.value * 2 * math.pi) + widget.swayPhase;
        final angle = math.sin(t) * 0.035; // ±2°
        return Transform.rotate(
          angle: angle,
          alignment: Alignment.bottomCenter,
          child: child,
        );
      },
      child: base,
    );
  }

  Widget _buildBloom() {
    final flower = _buildFlower(1.0);
    if (!_animate || _controller == null) {
      return flower;
    }
    final petalScale =
        CurvedAnimation(parent: _controller!, curve: Curves.easeOutBack);
    final petalFade = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
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
            child: _buildFlower(nucleusScale.value.clamp(0.0, 1.2)),
          ),
        );
      },
    );
  }

  Widget _buildFlower(double nucleusScale) {
    final d = widget.diameter;
    final nucleusD = d * 0.59;
    return SizedBox(
      width: d,
      height: d,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(d, d),
            painter: _SakuraPetalsPainter(
              edgeColor: LoveTreeService.petalEdge(widget.kind),
            ),
          ),
          Transform.scale(
            scale: nucleusScale,
            child: CustomPaint(
              size: Size(nucleusD, nucleusD),
              painter: _SakuraNucleusPainter(
                kind: widget.kind,
                color: LoveTreeService.nucleusColor(widget.kind),
              ),
              // The kind icon sits at the very centre of the nucleus.
              child: SizedBox(
                width: nucleusD,
                height: nucleusD,
                child: Center(
                  child: Icon(
                    LoveTreeService.nucleusIcon(widget.kind),
                    size: nucleusD * 0.34,
                    color: AppColors.white,
                    shadows: [
                      Shadow(
                        color: _shadeFlowerColor(
                                LoveTreeService.nucleusColor(widget.kind), -0.2)
                            .withValues(alpha: 0.35),
                        blurRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the 5 notched sakura petals with a 3-stop radial gradient (near-white
/// centre → mint pink → [edgeColor]) + a softly fading white edge, plus a faint
/// lift shadow under the bloom (§C.1).
class _SakuraPetalsPainter extends CustomPainter {
  _SakuraPetalsPainter({required this.edgeColor});

  final Color edgeColor;

  static const int _petalCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final petalLen = size.height * 0.46;

    // Lift shadow under the bloom (skip on tiny flowers).
    if (size.width >= 30) {
      canvas.drawOval(
        Rect.fromCenter(
          center: center.translate(0, 2),
          width: size.width * 0.60,
          height: size.height * 0.30,
        ),
        Paint()
          ..color = _shadeFlowerColor(edgeColor, -0.15).withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }

    final fillShader = RadialGradient(
      colors: [const Color(0xFFFFF0F4), const Color(0xFFFFD6E0), edgeColor],
      stops: const [0.0, 0.50, 1.0],
    ).createShader(Rect.fromCircle(center: Offset.zero, radius: petalLen));

    for (int i = 0; i < _petalCount; i++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(i * (2 * math.pi / _petalCount));

      final path = _sakuraPetalPath(petalLen);

      canvas.drawPath(path, Paint()..shader = fillShader);

      // Edge: white .40 at the base fading to .10 at the tip.
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppColors.white.withValues(alpha: 0.40),
            AppColors.white.withValues(alpha: 0.10),
          ],
        ).createShader(Rect.fromLTWH(
            -petalLen * 0.46, -petalLen, petalLen * 0.92, petalLen));
      canvas.drawPath(path, stroke);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_SakuraPetalsPainter oldDelegate) =>
      oldDelegate.edgeColor != edgeColor;
}

/// Paints the sakura nucleus (§C.2): a soft GLOW (no hard chip border) + a ring
/// of 6–7 cream-yellow stamen dots (the signature cherry feature) + a small
/// centre disc. The kind icon is layered on top by the widget.
class _SakuraNucleusPainter extends CustomPainter {
  _SakuraNucleusPainter({required this.kind, required this.color});

  final FlowerKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final center = Offset(size.width / 2, size.height / 2);

    // 1. Soft glow (replaces the hard chip border).
    canvas.drawCircle(
      center,
      d * 0.70,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: d * 0.70)),
    );

    // 2. Cream-yellow stamen dots on a ring (the sakura signature).
    const stamenCount = 7;
    final ringR = d * 0.32;
    final dotR = (d * 0.10).clamp(1.2, 3.0);
    final tipPaint = Paint()..color = const Color(0xFFFFF4D6);
    final stamenPaint = Paint()..color = const Color(0xFFFFE6A8);
    for (var i = 0; i < stamenCount; i++) {
      // Even spacing + a fixed per-dot offset so it reads organic, not robotic.
      final jitter = ((_bloomHash(i * 13 + 1) % 11) - 5) / 100.0;
      final a = (i / stamenCount) * 2 * math.pi + jitter;
      final p = center + Offset(math.cos(a) * ringR, math.sin(a) * ringR);
      canvas.drawCircle(p, dotR, stamenPaint);
      canvas.drawCircle(p.translate(-dotR * 0.3, -dotR * 0.3), dotR * 0.5, tipPaint);
    }

    // 3. Centre disc — a soft rounded volume (no thick white rim).
    final discR = d * 0.25;
    canvas.drawCircle(
      center,
      discR,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            _shadeFlowerColor(color, 0.12),
            color,
            _shadeFlowerColor(color, -0.08),
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: discR)),
    );
    // A faint inner enamel ring.
    canvas.drawCircle(
      center,
      discR - 0.8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6
        ..color = AppColors.white.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(_SakuraNucleusPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

// ── The v2.2 renderer ────────────────────────────────────────────────────────

/// The active v2.2 renderer: the tree is a [SakuraBranchPainter] and a flower is
/// a [_SakuraFlower]. Blossoms are anchored along the branch by
/// [_sakuraBloomPositions]; the bloom-glow / coach fallback anchor at the branch
/// tip. Honours the same [LoveTreeRenderer] contract as [PaintTreeRenderer].
class SakuraBranchRenderer extends LoveTreeRenderer {
  const SakuraBranchRenderer();

  @override
  CustomPainter treePainter({
    required LoveTreeStage stage,
    Season? season,
    bool skeleton = false,
  }) =>
      SakuraBranchPainter(stage: stage, season: season, skeleton: skeleton);

  @override
  Widget flowerWidget({
    required FlowerKind kind,
    required double diameter,
    required bool isNew,
    required int bloomOrder,
    required bool reduceMotion,
    double swayPhase = 0,
    AnimationController? ambient,
    VoidCallback? onTap,
  }) =>
      _SakuraFlower(
        kind: kind,
        diameter: diameter,
        isNew: isNew,
        bloomOrder: bloomOrder,
        reduceMotion: reduceMotion,
        swayPhase: swayPhase,
        ambient: ambient,
        onTap: onTap,
      );

  @override
  List<Offset> bloomPositions(LoveTreeStage stage, Size size, int count) =>
      _sakuraBloomPositions(stage, size, count);

  @override
  (Offset, double) canopyGeometry(LoveTreeStage stage, Size size) {
    final geo = _SakuraBranchGeometry(stage, size);
    return (geo.tipPoint, math.min(size.width, size.height) * 0.30);
  }
}
