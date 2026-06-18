import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/mood.dart';
import '../providers/auth_provider.dart';
import '../providers/mood_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'content_card.dart';

/// Localized label for a mood [key].
String moodLabel(AppLocalizations l10n, String key) {
  switch (key) {
    case 'happy':
      return l10n.moodHappy;
    case 'loved':
      return l10n.moodLoved;
    case 'missing':
      return l10n.moodMissing;
    case 'calm':
      return l10n.moodCalm;
    case 'meh':
      return l10n.moodMeh;
    case 'tired':
      return l10n.moodTired;
    case 'sad':
      return l10n.moodSad;
    case 'stressed':
      return l10n.moodStressed;
    default:
      return '';
  }
}

/// The "Tâm trạng hôm nay" Home card (feature mood): a daily, 1-tap emotional
/// check-in. Shows my mood + my partner's mood for today side by side — opening
/// the app to see how your person feels is the daily hook; sharing mine pings
/// them back. Partner's mood is always visible (care, not a gate); a soft nudge
/// invites me to share.
class MoodCard extends StatelessWidget {
  const MoodCard({super.key, required this.couple});

  final Couple couple;

  String _partnerName(BuildContext context, String? myUid) {
    final iAmCreator = myUid != null && myUid == couple.createdByUserId;
    final name = (iAmCreator ? couple.person2Name : couple.person1Name).trim();
    return name.isNotEmpty ? name : context.l10n.reactionPartnerFallback;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final mood = context.watch<MoodProvider>();
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final partnerName = _partnerName(context, myUid);

    final myMood = mood.myMood;
    final partnerMood = mood.partnerMood;

    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentLove.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(IconsaxPlusBold.emoji_happy,
                    size: 20, color: AppColors.accentLove),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.moodCardTitle,
                    style: AppTheme.sectionTitleStyle()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _MoodSide(
                    label: l10n.reactionYouLabel,
                    mood: myMood,
                    emptyText: l10n.moodNotSharedYou,
                    isMe: true,
                    onTap: () => _openPicker(context, myMood),
                  ),
                ),
                Container(
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: AppColors.surfaceLight,
                ),
                Expanded(
                  child: _MoodSide(
                    label: partnerName,
                    mood: partnerMood,
                    emptyText: l10n.moodPartnerEmpty(partnerName),
                    isMe: false,
                    onTap: null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildCta(context, l10n, myMood),
        ],
      ),
    );
  }

  Widget _buildCta(BuildContext context, AppLocalizations l10n, Mood? myMood) {
    final shared = myMood != null;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _openPicker(context, myMood),
          child: Ink(
            decoration: BoxDecoration(
              gradient: shared ? null : AppColors.sunsetRomance,
              color: shared ? AppColors.surfaceLight : null,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    shared ? IconsaxPlusLinear.edit_2 : IconsaxPlusBold.heart,
                    size: 18,
                    color: shared ? AppColors.textSecondary : AppColors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    shared ? l10n.moodUpdateCta : l10n.moodShareCta,
                    style: TextStyle(
                      color: shared ? AppColors.textSecondary : AppColors.white,
                      fontSize: 15,
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

  void _openPicker(BuildContext context, Mood? current) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<MoodProvider>.value(
        value: context.read<MoodProvider>(),
        child: _MoodPickerSheet(current: current),
      ),
    );
  }
}

/// One half of the card: a member's label + their mood (emoji + note) or an
/// empty prompt. The "me" half is tappable to open the picker.
class _MoodSide extends StatelessWidget {
  const _MoodSide({
    required this.label,
    required this.mood,
    required this.emptyText,
    required this.isMe,
    required this.onTap,
  });

  final String label;
  final Mood? mood;
  final String emptyText;
  final bool isMe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final option = mood?.option;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        if (option != null) ...[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentRose.withValues(alpha: 0.10),
            ),
            child: Text(option.emoji,
                style: const TextStyle(fontSize: 30, height: 1)),
          ),
          const SizedBox(height: 8),
          Text(
            moodLabel(l10n, mood!.mood),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (mood!.hasNote) ...[
            const SizedBox(height: 4),
            Text(
              '"${mood!.note}"',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.3,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ] else ...[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceLight,
            ),
            child: Icon(
              isMe ? IconsaxPlusLinear.add : IconsaxPlusLinear.emoji_normal,
              size: 24,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            emptyText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ],
    );

    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: content,
      );
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: content,
        ),
      ),
    );
  }
}

/// Bottom sheet to pick today's mood (+ optional short note). One tap on a mood
/// is enough; the note is optional. Mirrors the streak/records sheet styling.
class _MoodPickerSheet extends StatefulWidget {
  const _MoodPickerSheet({required this.current});

  final Mood? current;

  @override
  State<_MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends State<_MoodPickerSheet> {
  late String? _selected = widget.current?.mood;
  late final TextEditingController _noteController =
      TextEditingController(text: widget.current?.note ?? '');

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final key = _selected;
    if (key == null) {
      return;
    }
    HapticFeedback.lightImpact();
    await context
        .read<MoodProvider>()
        .setMood(key, note: _noteController.text);
    if (mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: const BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textTertiary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.moodSheetTitle,
                  textAlign: TextAlign.center,
                  style: AppTheme.displaySerif(
                    size: 22,
                    weight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 12,
                  children: [
                    for (final o in kMoodOptions)
                      _MoodChoice(
                        option: o,
                        label: moodLabel(l10n, o.key),
                        selected: _selected == o.key,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selected = o.key);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _noteController,
                  maxLength: kMoodNoteMaxLength,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: l10n.moodNoteHint,
                    counterText: '',
                    filled: true,
                    fillColor: AppColors.surfaceLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selected == null ? null : _save,
                    child: Text(l10n.moodSaveCta),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodChoice extends StatelessWidget {
  const _MoodChoice({
    required this.option,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final MoodOption option;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentRose.withValues(alpha: 0.14)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.accentLove : Colors.transparent,
            width: 1.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(option.emoji, style: const TextStyle(fontSize: 28, height: 1)),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? AppColors.accentLoveDeep
                    : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
