import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/animated_couple_name.dart';
import '../widgets/content_card.dart';
import '../widgets/shared_couple_photo_view.dart';
import '../widgets/sub_screen_header.dart';

/// What the user kept on the create-post screen: the photos to upload and the
/// single shared caption stamped on each one. Mirrors the old
/// `_GalleryDraftResult` so the gallery's upload path stays unchanged.
class CreatePostResult {
  const CreatePostResult({required this.files, required this.caption});

  final List<XFile> files;
  final String? caption;
}

/// "Tạo kỷ niệm" — full-screen compose route (design 2026-06-14) that replaces
/// the old `_GalleryDraftSheet` bottom sheet. Serves BOTH post flows:
///   - library ("Thêm hình") → starts with N photos → grid layout;
///   - camera ("Chụp hình")  → starts with 1 photo  → one large 4:5 photo;
/// the only difference is the input data — the layout is derived purely from
/// the current photo count (1 → big photo, ≥2 → 3-col grid). The screen never
/// uploads anything; it pops a [CreatePostResult] and the gallery runs the
/// shared `addPhotosBatch` path (single overlay + result snackbar).
///
/// Return contract (same as the old draft sheet): `pop(null)` or a result with
/// `files.isEmpty` = CANCEL (nothing posts); a result with `files.isNotEmpty`
/// = post.
class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, required this.initialFiles});

  /// The freshly picked/captured photos (1 from camera, N from the library).
  final List<XFile> initialFiles;

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final List<XFile> _files = List<XFile>.from(widget.initialFiles);
  final TextEditingController _caption = TextEditingController();

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  // ── Photo list mutations ────────────────────────────────────────────────

  void _removeAt(int index) {
    HapticFeedback.selectionClick();
    setState(() => _files.removeAt(index));
    if (_files.isEmpty) {
      // Removed every photo → close; the gallery treats an empty/null result as
      // a cancel (nothing uploads). Matches the old draft sheet behaviour.
      Navigator.of(context).pop();
    }
  }

  Future<void> _addMore() async {
    final picked = await ImagePicker().pickMultiImage(
      imageQuality: 85,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked.isEmpty || !mounted) {
      return;
    }
    // Append, deduping by path so the same photo can't be added twice.
    final existing = _files.map((f) => f.path).toSet();
    setState(() {
      for (final file in picked) {
        if (existing.add(file.path)) {
          _files.add(file);
        }
      }
    });
  }

  // ── Close / post ────────────────────────────────────────────────────────

  /// Only ask to discard when the user has invested effort writing a caption
  /// (removing photos doesn't count). Caption empty → close straight away.
  Future<void> _onClose() async {
    if (_caption.text.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    final l10n = context.l10n;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createPostDiscardTitle),
        content: Text(l10n.createPostDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.createPostDiscardKeep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.createPostDiscardConfirm,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _post() {
    if (_files.isEmpty) {
      return;
    }
    HapticFeedback.mediumImpact();
    final caption = _caption.text.trim();
    Navigator.of(context).pop(
      CreatePostResult(
        files: List<XFile>.from(_files),
        caption: caption.isEmpty ? null : caption,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final couple = context.watch<CoupleProvider>().couple;
    final canPost = _files.isNotEmpty;

    return PopScope(
      // Intercept the system back / iOS swipe-down so an unsaved caption can be
      // confirmed before the screen closes.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _onClose();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
          child: SafeArea(
            child: Column(
              children: [
                // App-wide header (đồng bộ toàn app 2026-06-14): the standard
                // SubScreenHeader — back ← + eyebrow chip — so there's a clear
                // way back. The "Đăng" action moved to a sticky bottom bar.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: SubScreenHeader(
                    badge: l10n.createPostBadge,
                    badgeIcon: IconsaxPlusLinear.magic_star,
                    onBack: _onClose,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ContentCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAuthorRow(l10n, couple),
                            const SizedBox(height: 12),
                            _buildCaptionField(l10n),
                            const SizedBox(height: 16),
                            if (_files.length == 1)
                              _buildSinglePhoto(l10n)
                            else
                              _buildPhotoGrid(l10n),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                _buildBottomPostBar(l10n, canPost),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Sticky bottom "Đăng" bar (primary action at thumb reach) ────────────

  Widget _buildBottomPostBar(AppLocalizations l10n, bool canPost) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: canPost ? _post : null,
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
          icon: const Icon(IconsaxPlusLinear.send_2, size: 18),
          label: Text(l10n.createPostBtn),
        ),
      ),
    );
  }

  // ── Author row (one-post header) ────────────────────────────────────────

  Widget _buildAuthorRow(AppLocalizations l10n, Couple? couple) {
    final authorName =
        context.read<AuthProvider>().currentUser?.displayName ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCoupleAvatar(couple, size: 44),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedCoupleName(
                person1Name: couple?.person1Name ?? '',
                person2Name: couple?.person2Name ?? '',
                creatorUserId: couple?.createdByUserId,
                heartSize: 12,
                heartColor: AppColors.accentRose,
                textStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.15,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.createPostAuthorMeta(authorName, l10n.today),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCoupleAvatar(Couple? couple, {double size = 44}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.primaryGradient,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.9),
          width: 2,
        ),
      ),
      child: ClipOval(
        child: SharedCouplePhotoView(
          localPath: couple?.couplePhotoPath,
          remoteUrl: couple?.couplePhotoUrl,
          fit: BoxFit.cover,
          decodeWidth: (size * MediaQuery.of(context).devicePixelRatio).round(),
          placeholder: Center(
            child: Text(
              _initialsFromCouple(couple),
              style: TextStyle(
                color: AppColors.white,
                fontSize: size * 0.3,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _initialsFromCouple(Couple? couple) {
    if (couple == null) {
      return '♥';
    }
    final first = couple.person1Name.trim().isNotEmpty
        ? couple.person1Name.trim().characters.first.toUpperCase()
        : 'A';
    final second = couple.person2Name.trim().isNotEmpty
        ? couple.person2Name.trim().characters.first.toUpperCase()
        : 'B';
    return '$first$second';
  }

  // ── Caption (large borderless field above the photos) ───────────────────

  Widget _buildCaptionField(AppLocalizations l10n) {
    // Soft inset field — NO hard outline. The app's global InputDecorationTheme
    // paints a rose enabled/focused border, so just setting `border:none` leaks
    // the rose ring through (it read as a validation box, user 2026-06-14 —
    // same gotcha as the chat composer). Override EVERY border state to none and
    // give it a gentle off-white fill so it stays friendly + clearly tappable.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: _caption,
        minLines: 2,
        maxLines: 6,
        maxLength: 280,
        textInputAction: TextInputAction.newline,
        keyboardType: TextInputType.multiline,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          height: 1.45,
        ),
        decoration: InputDecoration(
          hintText: l10n.createPostCaptionHint,
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isDense: true,
          counterText: '',
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  // ── Photo area — single (1 file) → big 4:5 ──────────────────────────────

  Widget _buildSinglePhoto(AppLocalizations l10n) {
    final path = _files.first.path;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(File(path), fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildRemoveButton(l10n, index: 0, diameter: 30),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildAddFromLibraryRow(l10n),
      ],
    );
  }

  Widget _buildAddFromLibraryRow(AppLocalizations l10n) {
    return Material(
      color: AppColors.accentRose.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _addMore,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accentRose.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                IconsaxPlusLinear.gallery_add,
                size: 18,
                color: AppColors.accentLoveDeep,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.createPostAddFromLibrary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accentLoveDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Photo area — multiple (≥2 files) → 3-col grid ───────────────────────

  Widget _buildPhotoGrid(AppLocalizations l10n) {
    // One extra cell at the end is always the "+ Add" tile.
    final itemCount = _files.length + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            if (index == _files.length) {
              return _buildGridAddTile(l10n);
            }
            return _buildGridPhotoTile(l10n, index);
          },
        ),
        const SizedBox(height: 12),
        Text(
          l10n.createPostPhotoCount(_files.length).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildGridPhotoTile(AppLocalizations l10n, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(File(_files[index].path), fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: _buildRemoveButton(l10n, index: index, diameter: 24),
        ),
      ],
    );
  }

  Widget _buildGridAddTile(AppLocalizations l10n) {
    return Material(
      color: AppColors.accentRose.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _addMore,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.accentRose.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                IconsaxPlusLinear.add,
                size: 22,
                color: AppColors.accentLoveDeep,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.createPostAddMore,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accentLoveDeep,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Remove (╳) button shared by both layouts ────────────────────────────

  Widget _buildRemoveButton(
    AppLocalizations l10n, {
    required int index,
    required double diameter,
  }) {
    return Semantics(
      label: l10n.createPostRemovePhoto,
      button: true,
      child: InkResponse(
        onTap: () => _removeAt(index),
        radius: diameter,
        child: Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 1.5),
          ),
          child: Icon(
            IconsaxPlusLinear.close_circle,
            size: diameter <= 24 ? 14 : 16,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
