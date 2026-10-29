import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/l10n.dart';
import '../services/analytics_service.dart';
import '../services/feedback_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_theme.dart';
import '../widgets/content_card.dart';
import '../widgets/sub_screen_header.dart';

/// "Góp ý & báo lỗi" (feature `feedback`). Từ Cài đặt: chọn Góp ý / Báo lỗi.
/// Từ thẻ chấm sao 1–3: [lowRating] != null → loại cố định = đánh giá thấp.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key, this.lowRating, this.source = 'settings'});

  final int? lowRating;
  final String source;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _text = TextEditingController();
  final FeedbackService _service = const FeedbackService();

  FeedbackType _type = FeedbackType.idea;
  File? _photo;
  bool _sending = false;
  bool _failed = false;
  bool _sent = false;

  bool get _isRating => widget.lowRating != null;
  FeedbackType get _effectiveType => _isRating ? FeedbackType.rating : _type;
  bool get _canSend => _text.text.trim().isNotEmpty && !_sending;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (x == null || !mounted) return;
      if (await x.length() > FeedbackService.maxPhotoBytes) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.feedbackPhotoTooLarge)));
        return;
      }
      setState(() => _photo = File(x.path));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.feedbackPhotoError)));
    }
  }

  Future<void> _send() async {
    if (!_canSend) return;
    FocusScope.of(context).unfocus();
    final locale = Localizations.localeOf(context).languageCode;
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await _service.submit(
        type: _effectiveType,
        message: _text.text,
        stars: widget.lowRating,
        screenshot: _photo,
        locale: locale,
      );
      if (!mounted) return;
      AnalyticsService.instance.logFeedbackSent(_effectiveType.name);
      HapticFeedback.lightImpact();
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failed = true;
      });
    }
  }

  String _hint() {
    final l10n = context.l10n;
    if (_isRating) return l10n.feedbackHintLowRating;
    return _type == FeedbackType.bug
        ? l10n.feedbackHintBug
        : l10n.feedbackHintSuggestion;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: l10n.feedbackBadge,
                  badgeIcon: IconsaxPlusBold.message_question,
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    16,
                    20,
                    16,
                    24 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.reduceMotion(context)
                          ? const Duration(milliseconds: 80)
                          : AppMotion.base,
                      child: _sent ? _buildSuccess(l10n) : _buildForm(l10n),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(AppLocalizations l10n) {
    return ContentCard(
      key: const ValueKey('success'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentLove.withValues(alpha: 0.12),
              ),
              child: const Icon(
                IconsaxPlusBold.tick_circle,
                size: 40,
                color: AppColors.accentLove,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              l10n.feedbackSuccessTitle,
              textAlign: TextAlign.center,
              style: AppTheme.displaySerif(size: 22, letterSpacing: 0, height: 1.25),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.feedbackSuccessBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            _PrimaryButton(
              label: l10n.feedbackDoneCta,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(AppLocalizations l10n) {
    final len = _text.text.characters.length;
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ContentCard(
          child: IgnorePointer(
            ignoring: _sending,
            child: Opacity(
              opacity: _sending ? 0.6 : 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isRating)
                    _RatedRow(stars: widget.lowRating!)
                  else
                    Row(
                      children: [
                        Expanded(
                          child: _TypeChip(
                            icon: IconsaxPlusLinear.message_text_1,
                            label: l10n.feedbackTypeSuggestion,
                            selected: _type == FeedbackType.idea,
                            onTap: () => setState(() => _type = FeedbackType.idea),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _TypeChip(
                            icon: IconsaxPlusLinear.danger,
                            label: l10n.feedbackTypeBug,
                            selected: _type == FeedbackType.bug,
                            onTap: () => setState(() => _type = FeedbackType.bug),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.feedbackFieldLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _text,
                    maxLength: FeedbackService.maxMessageLength,
                    minLines: 5,
                    maxLines: 8,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() => _failed = false),
                    decoration: InputDecoration(
                      hintText: _hint(),
                      counterText: '',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        l10n.feedbackCounter(len),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: len >= 1900
                              ? AppColors.accentLoveDeep
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _photo == null ? _attachButton(l10n) : _photoRow(l10n),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          IconsaxPlusLinear.info_circle,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.feedbackDeviceNote,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (_failed) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.30)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(IconsaxPlusLinear.danger, size: 18, color: AppColors.error),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.feedbackErrorBanner,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _PrimaryButton(
          label: _failed ? l10n.feedbackRetryCta : l10n.feedbackSendCta,
          loading: _sending,
          onPressed: _canSend ? _send : null,
        ),
      ],
    );
  }

  Widget _attachButton(AppLocalizations l10n) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _pickPhoto,
        icon: const Icon(IconsaxPlusLinear.gallery_add, size: 20),
        label: Text(
          l10n.feedbackAttachCta,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.white.withValues(alpha: 0.72),
          side: BorderSide(color: AppColors.textTertiary.withValues(alpha: 0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  Widget _photoRow(AppLocalizations l10n) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(_photo!, width: 72, height: 72, fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.feedbackPhotoLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        IconButton(
          tooltip: l10n.feedbackPhotoRemove,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () => setState(() => _photo = null),
          icon: const Icon(
            IconsaxPlusLinear.close_circle,
            size: 24,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textPrimary,
          disabledBackgroundColor: AppColors.textPrimary.withValues(alpha: 0.28),
          foregroundColor: AppColors.white,
          disabledForegroundColor: AppColors.white.withValues(alpha: 0.7),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.white : AppColors.textPrimary;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? AppColors.textPrimary
                : AppColors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(999),
            border: selected
                ? null
                : Border.all(color: AppColors.white.withValues(alpha: 0.60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: fg),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatedRow extends StatelessWidget {
  const _RatedRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentRose.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 18,
              color: i <= stars ? AppColors.accentLove : AppColors.textTertiary,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.l10n.feedbackRatedLabel(stars),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
