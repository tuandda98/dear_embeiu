import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/caro_game.dart';
import '../../providers/caro_game_provider.dart';
import '../../providers/couple_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../screens/rps_game_screen.dart' show rpsMemberName;
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/person_palette.dart';
import 'caro_board.dart';

/// Small local memory of the caro screens (Hive `app_settings`, a
/// `Box<String>`): the rule picked last time (design §3.2) and how many moves
/// I have played (the "chạm lại" hint shows for the first 5, §8.7).
abstract final class CaroPrefs {
  static const String box = 'app_settings';
  static const String lastRuleKey = 'caro_last_rule';
  static const String hintCountKey = 'caro_hint_count';
  static const int hintMoves = 5;

  /// main() opens `app_settings` before runApp; not open (tests) = no-op.
  static Future<Box<String>?> _open() async =>
      Hive.isBoxOpen(box) ? Hive.box<String>(box) : null;

  /// null = never started a game on this phone.
  static Future<CaroRule?> lastRule() async {
    final raw = (await _open())?.get(lastRuleKey);
    return raw == null ? null : CaroRule.fromKey(raw);
  }

  static Future<void> setLastRule(CaroRule rule) async {
    await (await _open())?.put(lastRuleKey, rule.key);
  }

  static Future<int> movesPlayed() async =>
      int.tryParse((await _open())?.get(hintCountKey) ?? '') ?? 0;

  static Future<void> countMove() async {
    final b = await _open();
    if (b == null) return;
    final n = int.tryParse(b.get(hintCountKey) ?? '') ?? 0;
    if (n < hintMoves) {
      await b.put(hintCountKey, '${n + 1}');
    }
  }
}

/// Names + colours of the two players as THIS phone shows them (colours from
/// the same source as sleep, design §8.5).
class CaroPeople {
  const CaroPeople({
    required this.myUid,
    required this.partnerUid,
    required this.myName,
    required this.partnerName,
    required this.myColor,
    required this.partnerColor,
  });

  final String myUid;
  final String partnerUid;
  final String myName;
  final String partnerName;
  final Color myColor;
  final Color partnerColor;

  factory CaroPeople.of(BuildContext context, AppLocalizations l10n) {
    final caro = context.watch<CaroGameProvider>();
    final couple = context.watch<CoupleProvider>().couple;
    final sleep = context.watch<SleepProvider>();
    final me = caro.myUid ?? '';
    final partner = caro.partnerUid ?? '';
    return CaroPeople(
      myUid: me,
      partnerUid: partner,
      myName: rpsMemberName(couple, me, l10n.rpsMeLabel),
      partnerName: rpsMemberName(couple, partner, l10n.reactionPartnerFallback),
      myColor: PersonPalette.colorOf(sleep.myColorId),
      partnerColor: PersonPalette.colorOf(sleep.partnerColorId),
    );
  }

  Color colorOfUid(String? uid) => uid == myUid ? myColor : partnerColor;
  String nameOf(String? uid) => uid == myUid ? myName : partnerName;

  /// Colour of X / O in [game] (X = whoever started it).
  Color colorX(CaroGame? game) =>
      game == null ? myColor : colorOfUid(game.playerX);
  Color colorO(CaroGame? game) =>
      game == null ? partnerColor : colorOfUid(game.playerO);

  /// "Tuấn 12 – 9 Thảo".
  String score(AppLocalizations l10n, int mine, int theirs) =>
      l10n.caroScore(myName, '$mine', '$theirs', partnerName);
}

/// "10:12" in the app locale.
String caroTime(BuildContext context, DateTime? at) {
  if (at == null) return '';
  return DateFormat.Hm(Localizations.localeOf(context).toString()).format(at);
}

/// Rule name ("Chặn hai đầu" / "Tự do").
String caroRuleName(AppLocalizations l10n, CaroRule rule) =>
    rule == CaroRule.free ? l10n.caroRuleFree : l10n.caroRuleVn;

/// Read-only rule explanation (design §3.3 "Sheet luật"): name, sentence,
/// edge note and the 7-square picture.
Future<void> showCaroRuleSheet(
  BuildContext context,
  CaroRule rule, {
  required Color colorX,
  required Color colorO,
}) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: CaroSheetHandle()),
            const SizedBox(height: 16),
            Text(
              caroRuleName(l10n, rule),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              rule == CaroRule.free
                  ? l10n.caroRuleFreeDesc
                  : l10n.caroRuleVnDesc,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.caroRuleEdgeNote,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CaroRuleExample(colorX: colorX, colorO: colorO),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule == CaroRule.free
                        ? l10n.caroRuleExampleWin
                        : l10n.caroRuleExampleNoWin,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class CaroSheetHandle extends StatelessWidget {
  const CaroSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFD9D3DB),
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

/// One lane of the "ba làn" strip (design C1): glyph + name, score, caption.
/// Lit lanes (whose turn it is / the winner) take the person's colour at .10.
class CaroLane extends StatelessWidget {
  const CaroLane({
    super.key,
    required this.name,
    required this.color,
    required this.side,
    required this.score,
    required this.caption,
    required this.lit,
    this.alignEnd = false,
    this.watchingDot = false,
  });

  final String name;
  final Color color;
  final CaroSide? side;
  final String score;
  final String caption;
  final bool lit;
  final bool alignEnd;
  final bool watchingDot;

  @override
  Widget build(BuildContext context) {
    final glyph = side == null
        ? const SizedBox.shrink()
        : CustomPaint(
            size: const Size.square(14),
            painter: _StonePainter(side!, color),
          );
    final nameText = Flexible(
      child: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
    final align = alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return AnimatedContainer(
      duration: AppMotion.reduceMotion(context)
          ? Duration.zero
          : AppMotion.base,
      curve: AppMotion.curve,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: lit ? color.withValues(alpha: 0.10) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Row(
            mainAxisAlignment: alignEnd
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: alignEnd
                ? [nameText, const SizedBox(width: 6), glyph]
                : [glyph, const SizedBox(width: 6), nameText],
          ),
          const SizedBox(height: 2),
          Text(
            score,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (watchingDot) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StonePainter extends CustomPainter {
  _StonePainter(this.side, this.color);

  final CaroSide side;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => paintCaroStone(
    canvas,
    size.center(Offset.zero),
    size.width * 1.2,
    side,
    color,
  );

  @override
  bool shouldRepaint(_StonePainter oldDelegate) =>
      oldDelegate.side != side || oldDelegate.color != color;
}

/// The three lanes: me · middle · partner (design C1, §3.3).
class CaroLanes extends StatelessWidget {
  const CaroLanes({
    super.key,
    required this.people,
    required this.myWins,
    required this.partnerWins,
    required this.mySide,
    required this.partnerSide,
    required this.midTop,
    required this.midBottom,
    this.litMe = false,
    this.litPartner = false,
    this.partnerWatching = false,
    this.myCaption,
    this.partnerCaption,
    this.onMidTap,
    this.midSemantics,
  });

  final CaroPeople people;
  final int myWins;
  final int partnerWins;
  final CaroSide? mySide;
  final CaroSide? partnerSide;
  final String midTop;
  final String midBottom;
  final bool litMe;
  final bool litPartner;
  final bool partnerWatching;
  final String? myCaption;
  final String? partnerCaption;

  /// Tap the rule name → rule sheet (null = not tappable, e.g. history).
  final VoidCallback? onMidTap;
  final String? midSemantics;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mid = ConstrainedBox(
      // Capped so the two name lanes keep their room on 360dp / large text;
      // the rule name wraps instead.
      constraints: const BoxConstraints(
        minWidth: 84,
        maxWidth: 96,
        minHeight: 44,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  midTop,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (onMidTap != null) ...[
                const SizedBox(width: 3),
                const Icon(
                  IconsaxPlusLinear.info_circle,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            midBottom,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: CaroLane(
            name: people.myName,
            color: people.myColor,
            side: mySide,
            score: '$myWins',
            caption: myCaption ?? l10n.caroLaneWins,
            lit: litMe,
          ),
        ),
        const SizedBox(width: 8),
        onMidTap == null
            ? mid
            : Semantics(
                button: true,
                label: midSemantics,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: onMidTap,
                  child: mid,
                ),
              ),
        const SizedBox(width: 8),
        Expanded(
          child: CaroLane(
            name: people.partnerName,
            color: people.partnerColor,
            side: partnerSide,
            score: '$partnerWins',
            caption:
                partnerCaption ??
                (partnerWatching ? l10n.caroLaneWatching : l10n.caroLaneWins),
            lit: litPartner,
            alignEnd: true,
            watchingDot: partnerWatching,
          ),
        ),
      ],
    );
  }
}
