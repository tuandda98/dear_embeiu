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
import 'animated_couple_name.dart';
import 'content_card.dart';
import 'mood_glyph.dart';

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
                child: const Icon(
                  IconsaxPlusBold.emoji_happy,
                  size: 20,
                  color: AppColors.accentLove,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.moodCardTitle,
                  style: AppTheme.sectionTitleStyle(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // When BOTH shared the SAME mood today, celebrate the sync with one big
          // glyph instead of two side-by-side (user 2026-06-19).
          if (myMood != null &&
              partnerMood != null &&
              myMood.mood == partnerMood.mood)
            _MoodMatched(
              myMood: myMood,
              partnerMood: partnerMood,
              myLabel: l10n.reactionYouLabel,
              partnerName: partnerName,
            )
          else
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
            child: MoodGlyph(option: option, size: 44),
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

/// Celebratory "in sync" state: when both shared the SAME mood today, one big
/// glyph in a gradient ring replaces the two-column layout (user 2026-06-19).
class _MoodMatched extends StatelessWidget {
  const _MoodMatched({
    required this.myMood,
    required this.partnerMood,
    required this.myLabel,
    required this.partnerName,
  });

  final Mood myMood;
  final Mood partnerMood;
  final String myLabel;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final option = myMood.option;

    // A soft rose "moment" panel that ties the whole in-sync state together
    // (đồng bộ with the app's tinted panels); inside, a glowing glyph + the two
    // names around a pulsing heart say "one mood, two of us" (đồng điệu).
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.accentRose.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glyph on a soft radial glow (no hard ring) + lifted white disc.
          SizedBox(
            width: 128,
            height: 128,
            child: Stack(
              alignment: Alignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentLove.withValues(alpha: 0.24),
                        AppColors.accentLove.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                  child: const SizedBox(width: 128, height: 128),
                ),
                Container(
                  width: 92,
                  height: 92,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cardSurface,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentRose.withValues(alpha: 0.18),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: option == null
                      ? const SizedBox.shrink()
                      : MoodGlyph(option: option, size: 60),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            moodLabel(l10n, myMood.mood),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          // Two names around a pulsing heart — reuses the app's couple-name motif.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  myLabel.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.pageEyebrowStyle(alpha: 0.6, shadowed: false),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: AnimatedHeartIcon(
                  size: 13,
                  color: AppColors.accentLoveDeep,
                ),
              ),
              Flexible(
                child: Text(
                  partnerName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTheme.pageEyebrowStyle(alpha: 0.6, shadowed: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.moodMatched,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentLoveDeep,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (myMood.hasNote || partnerMood.hasNote) ...[
            const SizedBox(height: 12),
            _note(myLabel, myMood),
            _note(partnerName, partnerMood),
          ],
        ],
      ),
    );
  }

  Widget _note(String name, Mood mood) {
    if (!mood.hasNote) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        '${name.toUpperCase()}: "${mood.note}"',
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
  late final TextEditingController _noteController = TextEditingController(
    text: widget.current?.note ?? '',
  );

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
    await context.read<MoodProvider>().setMood(key, note: _noteController.text);
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
                      horizontal: 16,
                      vertical: 12,
                    ),
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
            MoodGlyph(option: option, size: 40, animate: selected),
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
