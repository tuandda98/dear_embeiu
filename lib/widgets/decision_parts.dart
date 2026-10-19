import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/couple.dart';
import '../models/decision.dart';
import '../providers/auth_provider.dart';
import '../providers/couple_provider.dart';
import '../providers/decision_provider.dart';
import '../screens/decision_history_screen.dart';
import '../screens/decision_wheel_screen.dart';
import '../screens/gallery_screen.dart';
import '../services/analytics_service.dart';
import '../services/decision_service.dart';
import '../services/push_notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/decision_suggester.dart';

// Shared bits of "Chọn giúp chúng mình" (feature decision-wheel): display
// helpers, the two pill buttons, the result sheet and the open-… helpers used
// by the Home card, the wheel and the history.

IconData decisionKindIcon(DecisionKind kind, {bool bold = false}) {
  switch (kind) {
    case DecisionKind.eat:
      return bold ? IconsaxPlusBold.reserve : IconsaxPlusLinear.reserve;
    case DecisionKind.go:
      return bold ? IconsaxPlusBold.location : IconsaxPlusLinear.location;
    case DecisionKind.custom:
      return bold
          ? IconsaxPlusBold.message_question
          : IconsaxPlusLinear.message_question;
  }
}

Color decisionKindTint(DecisionKind kind) {
  switch (kind) {
    case DecisionKind.eat:
      return AppColors.accentRose;
    case DecisionKind.go:
      return AppColors.accentLavenderDeep;
    case DecisionKind.custom:
      return AppColors.textPrimary;
  }
}

bool decisionIsEnglish(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'en';

String _capitalizeFirst(String s) =>
    s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

/// The name to SHOW: a bank pick in the viewer's language (English activity
/// names get a capital — design §10), anything else as stored.
String decisionDisplayName(
  DecisionKind kind,
  String result,
  String resultId, {
  required bool english,
}) {
  final item = DecisionSuggester.bankItem(kind, resultId);
  if (item == null) {
    return result;
  }
  return english ? _capitalizeFirst(item.en) : item.vi;
}

String? decisionEmoji(DecisionKind kind, String resultId) =>
    DecisionSuggester.bankItem(kind, resultId)?.emoji;

/// "🍢 Bún chả" (emoji only for bank picks).
String decisionLine(Decision d, {required bool english}) {
  final name = decisionDisplayName(
    d.kind,
    d.result,
    d.resultId,
    english: english,
  );
  final emoji = decisionEmoji(d.kind, d.resultId);
  return emoji == null ? name : '$emoji $name';
}

/// "Ăn ngoài · nhanh gọn" for a bank item, the "added by us" tag for a
/// typed-in pick, "1 trong N lựa chọn" for custom.
String decisionTag(
  AppLocalizations l10n,
  DecisionKind kind, {
  String resultId = '',
  int optionCount = 0,
}) {
  if (kind == DecisionKind.custom) {
    return l10n.decisionTagCustomOf(optionCount);
  }
  final item = DecisionSuggester.bankItem(kind, resultId);
  if (item == null) {
    return kind == DecisionKind.eat
        ? l10n.decisionTagManualEat
        : l10n.decisionTagManualGo;
  }
  final parts = <String>[];
  if (kind == DecisionKind.eat) {
    if (item.has('nha') && item.has('ngoai')) {
      parts.add(l10n.decisionTagEither);
    } else if (item.has('nha')) {
      parts.add(l10n.decisionTagHomeCooked);
    } else if (item.has('ngoai')) {
      parts.add(l10n.decisionTagEatOut);
    }
    if (item.has('nhanh')) parts.add(l10n.decisionTagQuick);
    if (item.has('vua')) parts.add(l10n.decisionTagMedium);
    if (item.has('cau_ky')) parts.add(l10n.decisionTagFancy);
  } else {
    parts.add(item.has('nha') ? l10n.decisionTagStayIn : l10n.decisionTagGoOut);
    if (item.has('free')) parts.add(l10n.decisionTagFree);
    if (item.has('re')) parts.add(l10n.decisionTagCheap);
    if (item.has('ton')) parts.add(l10n.decisionTagPricey);
  }
  return parts.join(' · ');
}

String decisionTime(BuildContext context, DateTime? when) {
  if (when == null) return '';
  final locale = Localizations.localeOf(context).toLanguageTag();
  return decisionIsEnglish(context)
      ? DateFormat.jm(locale).format(when)
      : DateFormat.Hm(locale).format(when);
}

/// The partner's display name (MoodCard rule: the creator is person 1).
String decisionPartnerName(BuildContext context, Couple? couple) {
  final myUid = context.read<AuthProvider>().currentUser?.id;
  if (couple == null) return context.l10n.reactionPartnerFallback;
  final iAmCreator = myUid != null && myUid == couple.createdByUserId;
  final name = (iAmCreator ? couple.person2Name : couple.person1Name).trim();
  return name.isNotEmpty ? name : context.l10n.reactionPartnerFallback;
}

String decisionMyName(BuildContext context, Couple? couple) {
  final myUid = context.read<AuthProvider>().currentUser?.id;
  if (couple == null) return context.l10n.decisionMeFallback;
  final iAmCreator = myUid != null && myUid == couple.createdByUserId;
  final name = (iAmCreator ? couple.person1Name : couple.person2Name).trim();
  return name.isNotEmpty ? name : context.l10n.decisionMeFallback;
}

/// "Mình quay · 17:02" / "Tuấn quay · 17:02".
String decisionMeta(BuildContext context, Decision d) {
  final l10n = context.l10n;
  final myUid = context.read<AuthProvider>().currentUser?.id;
  final time = decisionTime(context, d.pickedAt);
  if (d.byUserId == myUid) {
    return l10n.decisionByMe(time);
  }
  final couple = context.read<CoupleProvider>().couple;
  return l10n.decisionByPartner(decisionPartnerName(context, couple), time);
}

/// Caption pre-filled by "Chụp lại" (D8): "Bún chả 🍢" · "{question} → {result}".
String decisionCaption(Decision d, {required bool english}) {
  if (d.kind == DecisionKind.custom) {
    return d.question.isEmpty ? d.result : '${d.question} → ${d.result}';
  }
  final name = decisionDisplayName(
    d.kind,
    d.result,
    d.resultId,
    english: english,
  );
  final emoji = decisionEmoji(d.kind, d.resultId);
  return emoji == null ? name : '$name $emoji';
}

// ── Buttons ────────────────────────────────────────────────────────────────

/// Pill h52 used across the feature: navy filled ([primary]) or white with a
/// navy .18 outline. [busy] shows a spinner and blocks taps.
class DecisionPillButton extends StatelessWidget {
  const DecisionPillButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.primary = true,
    this.busy = false,
    this.onBlush = false,
    this.semanticsLabel,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool primary;
  final bool busy;

  /// Outline variant sitting on the blush gradient (white .72 instead of
  /// solid white).
  final bool onBlush;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    final Color bg;
    final Color fg;
    if (primary) {
      bg = enabled || busy
          ? AppColors.textPrimary
          : AppColors.textPrimary.withValues(alpha: 0.28);
      fg = enabled || busy
          ? AppColors.white
          : AppColors.white.withValues(alpha: 0.70);
    } else {
      bg = onBlush ? AppColors.white.withValues(alpha: 0.72) : AppColors.white;
      fg = enabled
          ? AppColors.textPrimary
          : AppColors.textPrimary.withValues(alpha: 0.38);
    }
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: semanticsLabel != null,
      child: SizedBox(
        height: 52,
        child: Material(
          color: bg,
          shape: StadiumBorder(
            side: primary
                ? BorderSide.none
                : BorderSide(
                    color: AppColors.textPrimary.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            splashColor: primary
                ? AppColors.white.withValues(alpha: 0.12)
                : AppColors.accentRose.withValues(alpha: 0.08),
            child: Center(
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 18, color: fg),
                            const SizedBox(width: 8),
                            Text(
                              label,
                              style: TextStyle(
                                color: fg,
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
        ),
      ),
    );
  }
}

/// Text link, 14 w700 navy, 44 tall.
class DecisionLinkButton extends StatelessWidget {
  const DecisionLinkButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        textStyle: const TextStyle(
          fontFamily: AppTheme.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

// ── Navigation helpers ─────────────────────────────────────────────────────

/// Opens the wheel; after a commit it pops back here and this shows the
/// "Đã chốt…" SnackBar with "Chụp lại" (design §7).
Future<void> openDecisionWheel(
  BuildContext context, {
  DecisionKind kind = DecisionKind.eat,
  bool autoSpin = false,
  Decision? respinOf,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  // A leftover "Đã chốt" bar would cover the wheel's buttons.
  messenger.hideCurrentSnackBar();
  final written = await Navigator.of(context)
      .push<(Decision, DecisionCommitOutcome)>(
        MaterialPageRoute(
          settings: const RouteSettings(name: 'DecisionWheel'),
          builder: (_) => DecisionWheelScreen(
            initialKind: respinOf?.kind ?? kind,
            autoSpin: autoSpin,
            respinOf: respinOf,
          ),
        ),
      );
  if (written == null || !context.mounted) {
    return;
  }
  final (decision, outcome) = written;
  final couple = context.read<CoupleProvider>().couple;
  final String text;
  if (outcome == DecisionCommitOutcome.queued) {
    text = l10n.decisionCommittedQueued;
  } else if (couple == null || couple.isWaitingForPartner) {
    text = l10n.decisionCommittedSolo;
  } else {
    text = l10n.decisionCommittedPaired(decisionPartnerName(context, couple));
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        // With an action Flutter keeps the bar until dismissed; this one is
        // a 4s confirmation (design §7).
        persist: false,
        content: Text(text),
        action: SnackBarAction(
          label: l10n.decisionPhotoCta,
          onPressed: () {
            if (context.mounted) openDecisionPhoto(context, decision);
          },
        ),
      ),
    );
}

void openDecisionHistory(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'DecisionHistory'),
      builder: (_) => const DecisionHistoryScreen(),
    ),
  );
}

/// "Chụp lại" (D8): the Gallery camera flow with the caption pre-filled. The
/// Home shell flips to the Gallery tab while the photo uploads so the upload
/// overlay is visible.
Future<void> openDecisionPhoto(BuildContext context, Decision d) {
  AnalyticsService.instance.logDecisionPhotoCta(kind: d.kind.name);
  return captureAndPostPhoto(
    context,
    initialCaption: decisionCaption(d, english: decisionIsEnglish(context)),
    onPosting: () => NotificationTapRouter.pendingHomeTab.value = 2,
  );
}

// ── Result sheet (design B) ────────────────────────────────────────────────

Future<void> showDecisionResultSheet(BuildContext context, Decision d) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) =>
        _DecisionResultSheet(decisionId: d.id, fallback: d, outer: context),
  );
}

class _DecisionResultSheet extends StatelessWidget {
  const _DecisionResultSheet({
    required this.decisionId,
    required this.fallback,
    required this.outer,
  });

  final String decisionId;
  final Decision fallback;

  /// Home's context — navigation continues there once the sheet is closed.
  final BuildContext outer;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final english = decisionIsEnglish(context);
    // Live: the partner re-spinning while the sheet is open updates it.
    final d = context.select<DecisionProvider, Decision>(
      (p) =>
          [
            ?p.todayEat,
            ?p.todayGo,
            ...p.todayCustoms,
          ].where((x) => x.id == decisionId).firstOrNull ??
          fallback,
    );
    final isCustom = d.kind == DecisionKind.custom;
    final emoji = decisionEmoji(d.kind, d.resultId);
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final time = decisionTime(context, d.pickedAt);
    final by = d.byUserId == myUid
        ? l10n.decisionSheetByMe(time)
        : l10n.decisionSheetByPartner(
            decisionPartnerName(context, context.read<CoupleProvider>().couple),
            time,
          );
    final meta = d.spins > 1 ? '$by · ${l10n.decisionSheetSpins(d.spins)}' : by;

    void close(void Function() then) {
      Navigator.of(context).pop();
      if (outer.mounted) then();
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isCustom
                  ? d.question
                  : (d.kind == DecisionKind.eat
                        ? l10n.decisionRowEatLabel
                        : l10n.decisionRowGoLabel),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: isCustom ? 14 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: isCustom ? 0 : 1.2,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 96,
              height: 96,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentRose.withValues(alpha: 0.10),
              ),
              child: emoji != null
                  ? ExcludeSemantics(
                      child: Text(emoji, style: const TextStyle(fontSize: 56)),
                    )
                  : Icon(
                      decisionKindIcon(d.kind, bold: true),
                      size: 40,
                      color: decisionKindTint(d.kind),
                    ),
            ),
            const SizedBox(height: 14),
            Text(
              decisionDisplayName(
                d.kind,
                d.result,
                d.resultId,
                english: english,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              decisionTag(
                l10n,
                d.kind,
                resultId: d.resultId,
                optionCount: d.options.length,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meta,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DecisionPillButton(
                    primary: false,
                    label: l10n.decisionRespin,
                    icon: IconsaxPlusLinear.refresh,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      close(
                        () => openDecisionWheel(
                          outer,
                          autoSpin: true,
                          respinOf: d,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DecisionPillButton(
                    label: l10n.decisionPhotoCta,
                    icon: IconsaxPlusLinear.camera,
                    onPressed: () => close(() => openDecisionPhoto(outer, d)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 24,
              children: [
                DecisionLinkButton(
                  label: l10n.decisionHistoryLink,
                  icon: IconsaxPlusLinear.clock,
                  onPressed: () => close(() => openDecisionHistory(outer)),
                ),
                if (isCustom)
                  DecisionLinkButton(
                    label: l10n.decisionAskAnother,
                    icon: IconsaxPlusLinear.message_question,
                    onPressed: () => close(
                      () => openDecisionWheel(outer, kind: DecisionKind.custom),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
