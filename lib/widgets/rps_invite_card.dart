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

/// Home entry for rock-paper-scissors (feature rps-game, design §4.1 +
/// addendum 2026-09-14 §B) — sits right under the mood card in "Hôm nay của
/// chúng mình". Six states, in priority order ([RpsOpenState]):
///
/// 1. **myTurn** — the partner has thrown, I haven't: rose outline + dot,
///    "Người ấy đã ra rồi!" · CTA "Ra tay" (sunsetRomance);
/// 2. **invitedByPartner** — rose outline + dot, "Người ấy đang rủ!" ·
///    CTA "Vào chơi" (sunsetRomance) — the in-app badge for a pending invite;
/// 3. **unplayed** — a started round nobody has thrown in yet: "Ván đang dở"
///    · CTA "Ra tay" (navy);
/// 4. **awaitingPartner** — my hand is in: "Đang chờ người ấy ra" · CTA "Mở"
///    (outlined);
/// 5. **myInvitePending** — "Đang chờ người ấy…" · CTA "Mở" (outlined);
/// 6. **idle** — "Rủ người ấy một ván nhé" (+ this week's score when there
///    is one) · CTA "Chơi" (navy).
///
/// No-skip rule: a started round never expires, so states 1/3/4 can last for
/// days — tapping re-enters that round ("1 ván mở tại 1 thời điểm").
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
    final state = provider.openState;
    // Only the states where the partner is waiting on ME get the rose
    // outline + dot (design addendum N6).
    final highlighted =
        state == RpsOpenState.myTurn || state == RpsOpenState.invitedByPartner;

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
    final _CtaStyle ctaStyle;
    switch (state) {
      case RpsOpenState.myTurn:
        title = l10n.rpsPartnerMovedTitle;
        subtitle = l10n.rpsEntryMyTurnSubtitle;
        cta = l10n.rpsEntryCtaThrow;
        titleColor = AppColors.accentLoveDeep;
        ctaStyle = _CtaStyle.gradient;
      case RpsOpenState.invitedByPartner:
        title = l10n.rpsEntryInvitedTitle;
        subtitle = l10n.rpsEntryInvitedSubtitle;
        cta = l10n.rpsEntryCtaJoin;
        titleColor = AppColors.accentLoveDeep;
        ctaStyle = _CtaStyle.gradient;
      case RpsOpenState.unplayed:
        title = l10n.rpsEntryUnplayedTitle;
        subtitle = l10n.rpsEntryUnplayedSubtitle;
        cta = l10n.rpsEntryCtaThrow;
        titleColor = AppColors.textPrimary;
        ctaStyle = _CtaStyle.navy;
      case RpsOpenState.awaitingPartner:
        title = l10n.rpsEntryAwaitingTitle;
        subtitle = l10n.rpsEntryAwaitingSubtitle;
        cta = l10n.rpsEntryCtaOpen;
        titleColor = AppColors.textPrimary;
        ctaStyle = _CtaStyle.outlined;
      case RpsOpenState.myInvitePending:
        title = l10n.rpsWaitingPartner;
        subtitle = l10n.rpsEntryPendingSubtitle;
        cta = l10n.rpsEntryCtaOpen;
        titleColor = AppColors.textPrimary;
        ctaStyle = _CtaStyle.outlined;
      case RpsOpenState.none:
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
        ctaStyle = _CtaStyle.navy;
    }

    void handleTap() {
      HapticFeedback.selectionClick();
      openRpsGame(
        context,
        gameId: state == RpsOpenState.none ? null : open?.id,
      );
    }

    final card = ContentCard(
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          _Medallion(showDot: highlighted),
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
          _Cta(label: cta, style: ctaStyle),
        ],
      ),
    );

    // Rose outline when the partner is waiting on me (design D3 / N6).
    final outlined = AnimatedContainer(
      duration: AppMotion.reduceMotion(context)
          ? Duration.zero
          : AppMotion.base,
      curve: AppMotion.curve,
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accentLove.withValues(alpha: highlighted ? 0.45 : 0),
          width: 1.5,
        ),
      ),
      child: card,
    );

    // onTap on the node (Tester RPS-15) — the InkTile is excluded below.
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      onTap: handleTap,
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

/// 40pt pill: navy (idle / unplayed) · sunsetRomance (myTurn / invited) ·
/// outlined (awaitingPartner / myInvitePending).
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
