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

/// "Chat background" picker (Settings → Ảnh nền đoạn chat, 2026-06-18). Lets a
/// couple pick ONE photo to back the Chat tab instead of the gradient. The pick
/// is couple-shared (`prefs/home.chatBgPhotoId`), so both phones show the same
/// backdrop; picking "Mặc định" clears it back to the gradient.
///
/// Only photos with VALID dimensions are offered: portrait/square (height ≥
/// width) AND a short side ≥ [_minShortSide]px — a landscape or low-res photo
/// would crop badly or blur when stretched full-screen, so the picker hides it.
/// Validity is measured by decoding each candidate's real pixel size.
class ChatBgScreen extends StatefulWidget {
  const ChatBgScreen({super.key});

  @override
  State<ChatBgScreen> createState() => _ChatBgScreenState();
}

class _ChatBgScreenState extends State<ChatBgScreen> {
  static const String _coupleKey = 'couple';

  /// A chat background must be at least this wide on its shorter side so it
  /// stays sharp filling a ~1080px+ phone screen.
  static const int _minShortSide = 720;

  final HomePrefsService _prefs = HomePrefsService();

  late final String _coupleId;

  /// Currently picked key (photo id or 'couple'); null = "Mặc định" (gradient).
  String? _selected;

  /// The on-disk pick at entry — drives the Save button + discard guard.
  String? _initial;

  /// Measured pixel sizes per candidate key: a present non-null value means
  /// "measured & we know its dimensions"; a present null means "measured but
  /// failed/undecodable"; absent means "not measured yet".
  final Map<String, ({int w, int h})?> _dims = <String, ({int w, int h})?>{};

  /// Keys we've already kicked off a measurement for (avoids re-decoding).
  final Set<String> _requested = <String>{};

  @override
  void initState() {
    super.initState();
    _coupleId = context.read<CoupleProvider>().couple?.id ?? '';
    _selected = _loadCachedSelection();
    _initial = _selected;
  }

  bool get _dirty => _selected != _initial;

  /// Offline-first: seed the pick from the Hive cache the Chat tab keeps in
  /// sync (`chat_bg_photo_<coupleId>`). Empty string = no background.
  String? _loadCachedSelection() {
    if (_coupleId.isEmpty) {
      return null;
    }
    try {
      final raw =
          Hive.box<String>('app_settings').get('chat_bg_photo_$_coupleId');
      return (raw == null || raw.isEmpty) ? null : raw;
    } catch (_) {
      return null;
    }
  }

  void _pick(String? key) {
    HapticFeedback.selectionClick();
    setState(() => _selected = key);
  }

  /// True once a candidate is measured and passes the portrait + sharpness bar.
  bool _isValid(String key) {
    final dim = _dims[key];
    return dim != null && dim.h >= dim.w && dim.w >= _minShortSide;
  }

  bool _isMeasured(String key) => _dims.containsKey(key);

  /// Resolve the best image provider for a candidate: the on-disk file when it
  /// exists (instant, offline), else the network URL.
  ImageProvider? _providerFor(_BgItem item) {
    final local = item.local;
    if (local != null && local.trim().isNotEmpty) {
      final file = File(local);
      if (file.existsSync()) {
        return FileImage(file);
      }
    }
    final remote = item.remote;
    if (remote != null && remote.trim().isNotEmpty) {
      return CachedNetworkImageProvider(remote);
    }
    return null;
  }

  /// Decode a candidate's real dimensions once, then re-filter the grid.
  void _measure(_BgItem item) {
    if (!_requested.add(item.key)) {
      return;
    }
    final provider = _providerFor(item);
    if (provider == null) {
      _dims[item.key] = null;
      return;
    }
    final stream = provider.resolve(const ImageConfiguration());
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        stream.removeListener(listener);
        if (!mounted) {
          return;
        }
        setState(() {
          _dims[item.key] = (w: info.image.width, h: info.image.height);
        });
      },
      onError: (_, _) {
        stream.removeListener(listener);
        if (!mounted) {
          return;
        }
        setState(() => _dims[item.key] = null);
      },
    );
    stream.addListener(listener);
  }

  /// Commits the pick: mirror into the Hive cache the Chat tab reads, publish
  /// to the couple (fail-soft), confirm, then close. The Chat tab's watcher
  /// repaints both phones.
  Future<void> _onSave() async {
    HapticFeedback.mediumImpact();
    final value = _selected ?? '';
    try {
      Hive.box<String>('app_settings')
          .put('chat_bg_photo_$_coupleId', value);
    } catch (_) {
      // Cache best-effort.
    }
    if (_coupleId.isNotEmpty) {
      unawaited(_prefs.setChatBg(_coupleId, value));
    }
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(context.l10n.chatBgSavedMsg)));
    setState(() => _initial = _selected);
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

  /// All candidate photos: couple cover first, then every gallery photo that
  /// has an image. Validity is applied later, after each is measured.
  List<_BgItem> _candidates(Couple? couple, List<Photo> photos) {
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
    final candidates = _candidates(couple, photos);

    // Kick off measurement for any not-yet-seen candidate.
    for (final item in candidates) {
      if (!_requested.contains(item.key)) {
        _measure(item);
      }
    }

    final valid =
        candidates.where((c) => _isValid(c.key)).toList(growable: false);
    final stillMeasuring = candidates.any((c) => !_isMeasured(c.key));

    return PopScope(
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
                      badge: l10n.chatBgBadge,
                      badgeIcon: IconsaxPlusLinear.gallery,
                      title: l10n.chatBgTitle,
                      subtitle: l10n.chatBgSubtitle,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _FilterHint(text: l10n.chatBgFilterHint),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 0.62, // portrait tiles, like the bg
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // Index 0 is always the "default gradient" tile.
                        if (index == 0) {
                          return _NoneTile(
                            label: l10n.chatBgNoneLabel,
                            selected: _selected == null,
                            onTap: () => _pick(null),
                          );
                        }
                        final item = valid[index - 1];
                        return _BgTile(
                          item: item,
                          selected: _selected == item.key,
                          coverLabel: l10n.counterBgCoverLabel,
                          onTap: () => _pick(item.key),
                        );
                      },
                      childCount: valid.length + 1,
                    ),
                  ),
                ),
                if (stillMeasuring)
                  SliverToBoxAdapter(
                    child: _MeasuringRow(text: l10n.chatBgMeasuring),
                  )
                else if (valid.isEmpty)
                  SliverToBoxAdapter(
                    child: _NoValidHint(l10n: l10n),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

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

/// The first tile: clears the background back to the gradient.
class _NoneTile extends StatelessWidget {
  const _NoneTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
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
            const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.dawnBlush),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    IconsaxPlusLinear.slash,
                    size: 26,
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selected) const _SelectedOverlay(),
          ],
        ),
      ),
    );
  }
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
            if (!selected)
              Container(color: Colors.black.withValues(alpha: 0.08)),
            if (selected) const _SelectedOverlay(),
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

/// Shared rose ring + check badge for the picked tile.
class _SelectedOverlay extends StatelessWidget {
  const _SelectedOverlay();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentLove, width: 3),
          ),
        ),
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
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.local, this.remote});

  final String? local;
  final String? remote;

  @override
  Widget build(BuildContext context) {
    final placeholder =
        Container(color: AppColors.accentRose.withValues(alpha: 0.10));
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

/// Soft rounded info chip explaining the filter.
class _FilterHint extends StatelessWidget {
  const _FilterHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(IconsaxPlusLinear.info_circle,
              size: 16, color: AppColors.accentLove),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasuringRow extends StatelessWidget {
  const _MeasuringRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accentLove,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoValidHint extends StatelessWidget {
  const _NoValidHint({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(IconsaxPlusLinear.gallery,
                size: 34, color: AppColors.accentLove),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.chatBgNoneValidTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.chatBgNoneValidBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
