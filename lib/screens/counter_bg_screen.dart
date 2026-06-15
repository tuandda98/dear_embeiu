import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/photo.dart';
import '../providers/couple_provider.dart';
import '../providers/photo_provider.dart';
import '../services/home_prefs_service.dart';
import '../theme/app_colors.dart';
import '../widgets/sub_screen_header.dart';

/// "Counter background" picker (Settings → Ảnh nền thẻ đếm, 2026-06-14). Lets a
/// couple choose WHICH photos may back the Home hero counter card. The chosen
/// set is a couple-shared whitelist (`prefs/home.counterBgPhotoIds`); the Home
/// card then cycles only through those. Picking NONE means "no restriction" —
/// the card cycles through everything, the original behaviour.
class CounterBgScreen extends StatefulWidget {
  const CounterBgScreen({super.key});

  @override
  State<CounterBgScreen> createState() => _CounterBgScreenState();
}

class _CounterBgScreenState extends State<CounterBgScreen> {
  static const String _coupleKey = 'couple';

  final HomePrefsService _prefs = HomePrefsService();

  late final String _coupleId;
  Set<String> _selected = <String>{};

  /// The on-disk selection at entry — used to tell whether there are unsaved
  /// edits (drives the Save button + the discard-on-back guard).
  Set<String> _initial = <String>{};

  @override
  void initState() {
    super.initState();
    _coupleId = context.read<CoupleProvider>().couple?.id ?? '';
    _selected = _loadCachedSelection();
    _initial = <String>{..._selected};
  }

  bool get _dirty =>
      _selected.length != _initial.length || !_selected.containsAll(_initial);

  /// Offline-first: seed the selection from the Hive cache the Home tab keeps
  /// in sync (`counter_bg_ids_<coupleId>`, newline-joined ids).
  Set<String> _loadCachedSelection() {
    if (_coupleId.isEmpty) {
      return <String>{};
    }
    try {
      final raw = Hive.box<String>('app_settings').get('counter_bg_ids_$_coupleId');
      if (raw == null || raw.isEmpty) {
        return <String>{};
      }
      return raw.split('\n').where((s) => s.isNotEmpty).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  void _toggle(String key) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.add(key)) {
        _selected.remove(key);
      }
    });
  }

  /// Commits the selection: mirror into the Hive cache Home reads, publish to
  /// the couple (fail-soft), confirm with a snackbar, then close. Home's watcher
  /// re-filters both phones.
  Future<void> _onSave() async {
    HapticFeedback.mediumImpact();
    final ids = _selected.toList(growable: false);
    try {
      Hive.box<String>('app_settings')
          .put('counter_bg_ids_$_coupleId', ids.join('\n'));
    } catch (_) {
      // Cache best-effort.
    }
    if (_coupleId.isNotEmpty) {
      unawaited(_prefs.setCounterBgIds(_coupleId, ids));
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(context.l10n.counterBgSavedMsg)));
    // Mark the selection clean so the discard guard (PopScope.canPop) won't
    // fire, then close on the next frame — by then canPop reflects the saved
    // (no-longer-dirty) state, so the pop goes through without the dialog.
    setState(() => _initial = <String>{..._selected});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).maybePop();
      }
    });
  }

  /// Back/swipe-away with unsaved edits → confirm before discarding.
  Future<void> _confirmDiscard() async {
    final l10n = context.l10n;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.counterBgDiscardTitle),
        content: Text(l10n.counterBgDiscardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.counterBgDiscardLeave),
          ),
        ],
      ),
    );
    if (leave == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  /// Builds the pickable list: the couple cover photo first, then every loaded
  /// gallery photo that has an image. Mirrors Home's candidate keys ('couple'
  /// or the photo id) so a pick maps 1:1 to a background.
  List<_BgItem> _items(Couple? couple, List<Photo> photos) {
    return [
      if (couple != null &&
          ((couple.couplePhotoUrl?.trim().isNotEmpty ?? false) ||
              (couple.couplePhotoPath?.trim().isNotEmpty ?? false)))
        _BgItem(
          key: _coupleKey,
          local: couple.couplePhotoPath,
          remote: couple.couplePhotoUrl,
          isCover: true,
        ),
      for (final p in photos)
        if (p.hasLocalPath || p.hasRemoteUrl)
          _BgItem(key: p.id, local: p.path, remote: p.remoteUrl),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final couple = context.watch<CoupleProvider>().couple;
    final photos = context.watch<PhotoProvider>().sortedPhotos;
    final items = _items(couple, photos);

    return PopScope(
      // Guard unsaved edits: block the auto-pop, confirm first.
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _confirmDiscard();
        }
      },
      child: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          bottomNavigationBar: _buildSaveBar(l10n),
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                    child: SubScreenHeader(
                      badge: l10n.counterBgBadge,
                      badgeIcon: IconsaxPlusLinear.gallery,
                      title: l10n.counterBgTitle,
                      subtitle: _selected.isEmpty
                          ? l10n.counterBgSubtitleAll
                          : l10n.counterBgSubtitleCount(_selected.length),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _Empty(l10n: l10n),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return _BgTile(
                            item: item,
                            selected: _selected.contains(item.key),
                            coverLabel: l10n.counterBgCoverLabel,
                            onTap: () => _toggle(item.key),
                          );
                        },
                        childCount: items.length,
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

  /// Sticky bottom Save bar (primary action at thumb reach — same recipe as
  /// the compose screen). Enabled only when there are unsaved edits.
  Widget _buildSaveBar(AppLocalizations l10n) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: _dirty ? _onSave : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentLove,
              foregroundColor: AppColors.white,
              disabledBackgroundColor:
                  AppColors.accentLove.withValues(alpha: 0.40),
              disabledForegroundColor: AppColors.white.withValues(alpha: 0.9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(IconsaxPlusLinear.tick_circle, size: 18),
            label: Text(l10n.counterBgSave),
          ),
        ),
      ),
    );
  }
}

class _BgItem {
  const _BgItem({
    required this.key,
    this.local,
    this.remote,
    this.isCover = false,
  });

  final String key;
  final String? local;
  final String? remote;
  final bool isCover;
}

class _BgTile extends StatelessWidget {
  const _BgTile({
    required this.item,
    required this.selected,
    required this.coverLabel,
    required this.onTap,
  });

  final _BgItem item;
  final bool selected;
  final String coverLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumb(local: item.local, remote: item.remote),
            // Dim unselected tiles a touch so the picked ones pop.
            if (!selected)
              Container(color: Colors.black.withValues(alpha: 0.08)),
            // Selected: rose ring + check badge.
            if (selected)
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentLove, width: 3),
                ),
              ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.accentLove,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 16, color: AppColors.white),
                ),
              ),
            if (item.isCover)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    coverLabel,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

class _Thumb extends StatelessWidget {
  const _Thumb({this.local, this.remote});

  final String? local;
  final String? remote;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(color: AppColors.accentRose.withValues(alpha: 0.10));
    // Local cache first (instant, offline); fall back to the network URL.
    if (local != null && local!.trim().isNotEmpty) {
      final file = File(local!);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover, errorBuilder: (_, _, _) {
          return _network(remote, placeholder);
        });
      }
    }
    return _network(remote, placeholder);
  }

  Widget _network(String? url, Widget placeholder) {
    if (url == null || url.trim().isEmpty) {
      return placeholder;
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
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
              child: const Icon(IconsaxPlusLinear.gallery,
                  size: 38, color: AppColors.accentLove),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.counterBgEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.counterBgEmptyBody,
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
