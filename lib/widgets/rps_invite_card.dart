import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../providers/rps_game_provider.dart';
import '../screens/rps_game_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import 'content_card.dart';
import 'ink_tile.dart';

/// Medallion gradient for the game entry points (design §0 proposal
/// `_MedalPalette.game`: peach → sunset1, warmer than the five existing
/// medals so it reads as its own badge). Shared with the Profile badge.
const List<Color> rpsMedalGradient = <Color>[
  Color(0xFFFFA46B),
  AppColors.sunset1,
];

/// Accent for the game medal glow / inbox icon.
const Color rpsMedalAccent = Color(0xFFF26D5B);

/// Home entry for rock-paper-scissors (feature rps-game, design §4.1) —
/// sits right under the mood card in "Hôm nay của chúng mình". Three states:
///
/// - **idle** — "Rủ người ấy một ván nhé" (+ this week's score when there is
///   one) · CTA "Chơi" (navy);
/// - **invitedByPartner** — rose outline + dot, "Người ấy đang rủ!" ·
///   CTA "Vào chơi" (sunsetRomance) — the in-app badge for a pending invite;
/// - **myInvitePending** — "Đang chờ người ấy…" · CTA "Mở" (outlined).
///
/// The whole card is tappable (InkTile ripple); the CTA is the visual
/// affordance. Hidden by the caller while the couple is still waiting for a
/// partner (same rule as the mood card).
class RpsInviteCard extends StatelessWidget {
  const RpsInviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final provider = context.watch<RpsGameProvider>();
    final open = provider.openGame;
    final me = provider.myUid;
    final invited = provider.hasPendingInvite;
    final pending =
        !invited &&
        open != null &&
        open.isOpen &&
        me != null &&
        open.isCreatedBy(me) &&
        !open.isInviteStale();

    // Week score needs the first history page — one lazy load, cached in the
    // provider (no shimmer here: the card just shows the idle subtitle until
    // the numbers land, to avoid a flicker on every Home build).
    if (!provider.isHistoryLoaded && !provider.isLoadingHistory) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.read<RpsGameProvider>().loadHistory();
        }
      });
    }

    final String title;
    final String subtitle;
    final String cta;
    final Color titleColor;
    if (invited) {
      title = l10n.rpsEntryInvitedTitle;
      subtitle = l10n.rpsEntryInvitedSubtitle;
      cta = l10n.rpsEntryCtaJoin;
      titleColor = AppColors.accentLoveDeep;
    } else if (pending) {
      title = l10n.rpsWaitingPartner;
      subtitle = l10n.rpsEntryPendingSubtitle;
      cta = l10n.rpsEntryCtaOpen;
      titleColor = AppColors.textPrimary;
    } else {
      final week = provider.weekScore;
      final nf = NumberFormat.decimalPattern(
        Localizations.localeOf(context).toString(),
      );
      title = l10n.rpsGameTitle;
      subtitle = week.total == 0
          ? l10n.rpsEntryIdleSubtitle
          : l10n.rpsEntryWeekScore(
              nf.format(week.wins),
              nf.format(week.draws),
              nf.format(week.losses),
            );
      cta = l10n.rpsEntryCtaPlay;
      titleColor = AppColors.textPrimary;
    }

    void handleTap() {
      HapticFeedback.selectionClick();
      openRpsGame(context, gameId: (invited || pending) ? open?.id : null);
    }

    final card = ContentCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _Medallion(showDot: invited),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _Cta(
            label: cta,
            style: invited
                ? _CtaStyle.gradient
                : (pending ? _CtaStyle.outlined : _CtaStyle.navy),
          ),
        ],
      ),
    );

    // Rose outline when the partner is waiting on me (design D3).
    final outlined = AnimatedContainer(
      duration: AppMotion.reduceMotion(context)
          ? Duration.zero
          : AppMotion.base,
      curve: AppMotion.curve,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accentLove.withValues(alpha: invited ? 0.45 : 0),
          width: 1.5,
        ),
      ),
      child: card,
    );

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ExcludeSemantics(
        child: InkTile(borderRadius: 24, onTap: handleTap, child: outlined),
      ),
    );
  }
}

class _Medallion extends StatelessWidget {
  const _Medallion({required this.showDot});

  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: rpsMedalGradient,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: rpsMedalAccent.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            '✌️✊✋',
            style: TextStyle(fontSize: 13, height: 1, letterSpacing: -1),
          ),
        ),
        if (showDot)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppColors.accentLove,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 1.5),
              ),
            ),
          ),
      ],
    );
  }
}

enum _CtaStyle { navy, gradient, outlined }

/// 40pt pill: navy (idle) · sunsetRomance (invited) · outlined (pending).
/// Purely visual — the InkTile over the whole card handles the tap.
class _Cta extends StatelessWidget {
  const _Cta({required this.label, required this.style});

  final String label;
  final _CtaStyle style;

  @override
  Widget build(BuildContext context) {
    final outlined = style == _CtaStyle.outlined;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: style == _CtaStyle.navy ? AppColors.textPrimary : null,
        gradient: style == _CtaStyle.gradient ? AppColors.sunsetRomance : null,
        borderRadius: BorderRadius.circular(999),
        border: outlined
            ? Border.all(color: AppColors.textPrimary, width: 1.4)
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: outlined ? AppColors.textPrimary : AppColors.white,
        ),
      ),
    );
  }
}
