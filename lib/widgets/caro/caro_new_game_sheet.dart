import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/caro_game.dart';
import '../../providers/caro_game_provider.dart';
import '../../screens/caro_game_screen.dart';
import '../../services/analytics_service.dart';
import '../../services/caro_game_service.dart';
import '../../theme/app_colors.dart';
import 'caro_board.dart';
import 'caro_common.dart';

/// "Rủ … chơi caro" (design §3.2, §13 U1): pick the rule (pre-selected with
/// the one used last time on this phone), then either start right away with
/// the first stone in the centre (2 taps from Home) or choose the first
/// square on an empty board. [rematchOf] = the finished game this follows.
Future<void> showCaroNewGameSheet(
  BuildContext context, {
  String? rematchOf,
}) async {
  final last = await CaroPrefs.lastRule();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    routeSettings: const RouteSettings(name: 'CaroNewGameSheet'),
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => CaroNewGameSheet(
      lastRule: last,
      rematchOf: rematchOf,
      hostContext: context,
    ),
  );
}

/// Home "Chơi" (user 2026-10-23, like Oẳn tù tì): one tap sends the invite —
/// rule used last time on this phone (first game: "Chặn hai đầu"), first
/// stone in the centre — then opens the game. The rule sheet stays for
/// "Ván mới" / "Phục thù" inside the game and history screens.
Future<void> quickStartCaroGame(
  BuildContext context, {
  String? rematchOf,
}) async {
  final caro = context.read<CaroGameProvider>();
  if (caro.isBusy) return;
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.maybeOf(context);
  final rule = await CaroPrefs.lastRule() ?? CaroRule.vn;
  final result = await caro.start(rule: rule, rematchOf: rematchOf);
  final gameId = result.gameId;
  if ((result.isOk || result.status == CaroActionStatus.alreadyOpen) &&
      gameId != null) {
    if (result.isOk) {
      await CaroPrefs.setLastRule(rule);
      AnalyticsService.instance.logCaroGameStarted(
        rematch: rematchOf != null,
        rule: rule.key,
      );
    }
    if (context.mounted) openCaroGame(context, gameId: gameId, source: null);
    return;
  }
  messenger?.showSnackBar(
    SnackBar(
      content: Text(
        result.status == CaroActionStatus.network
            ? l10n.caroOffline
            : l10n.caroSendError,
      ),
    ),
  );
}

class CaroNewGameSheet extends StatefulWidget {
  const CaroNewGameSheet({
    super.key,
    required this.lastRule,
    required this.hostContext,
    this.rematchOf,
  });

  /// Rule saved last time (null = first game here → "Chặn hai đầu", no tag).
  final CaroRule? lastRule;
  final String? rematchOf;

  /// The page that opened the sheet (navigation after it closes).
  final BuildContext hostContext;

  @override
  State<CaroNewGameSheet> createState() => _CaroNewGameSheetState();
}

class _CaroNewGameSheetState extends State<CaroNewGameSheet> {
  late CaroRule _rule = widget.lastRule ?? CaroRule.vn;
  bool _busy = false;
  String? _error;

  Future<void> _start() async {
    if (_busy) return;
    HapticFeedback.selectionClick();
    setState(() {
      _busy = true;
      _error = null;
    });
    final l10n = context.l10n;
    final result = await context.read<CaroGameProvider>().start(
      rule: _rule,
      rematchOf: widget.rematchOf,
    );
    if (!mounted) return;
    final gameId = result.gameId;
    if ((result.isOk || result.status == CaroActionStatus.alreadyOpen) &&
        gameId != null) {
      if (result.isOk) {
        await CaroPrefs.setLastRule(_rule);
        AnalyticsService.instance.logCaroGameStarted(
          rematch: widget.rematchOf != null,
          rule: _rule.key,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      final host = widget.hostContext;
      if (host.mounted) {
        openCaroGame(host, gameId: gameId, source: null);
      }
      return;
    }
    setState(() {
      _busy = false;
      _error = result.status == CaroActionStatus.network
          ? l10n.caroOffline
          : l10n.caroSendError;
    });
  }

  void _pickFirst() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop();
    final host = widget.hostContext;
    if (host.mounted) {
      openCaroDraft(host, rule: _rule, rematchOf: widget.rematchOf);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final people = CaroPeople.of(context, l10n);
    Widget option(CaroRule rule) => _RuleOption(
      rule: rule,
      selected: _rule == rule,
      lastUsed: widget.lastRule == rule,
      colorX: people.myColor,
      colorO: people.partnerColor,
      onTap: _busy ? null : () => setState(() => _rule = rule),
    );
    // Scrolls when taller than the screen (360×640, large text — review
    // UI #2).
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: CaroSheetHandle()),
            const SizedBox(height: 16),
            Text(
              l10n.caroNewTitle(people.partnerName),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.caroNewSub,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            option(CaroRule.vn),
            const SizedBox(height: 12),
            option(CaroRule.free),
            const SizedBox(height: 16),
            Text(
              l10n.caroNewFirstNote(people.partnerName),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(fontSize: 13, color: AppColors.errorInk),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : _start,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.textPrimary,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Text(
                        l10n.caroNewCta(people.partnerName),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: _busy ? null : _pickFirst,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  foregroundColor: AppColors.textPrimary,
                ),
                child: Text(
                  l10n.caroNewPickFirst,
                  style: const TextStyle(
                    fontSize: 14,
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

class _RuleOption extends StatelessWidget {
  const _RuleOption({
    required this.rule,
    required this.selected,
    required this.lastUsed,
    required this.colorX,
    required this.colorO,
    required this.onTap,
  });

  final CaroRule rule;
  final bool selected;
  final bool lastUsed;
  final Color colorX;
  final Color colorO;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final free = rule == CaroRule.free;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.white : AppColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? AppColors.textPrimary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Radio(selected: selected),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              caroRuleName(l10n, rule),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (lastUsed) ...[
                            const SizedBox(width: 8),
                            Text(
                              l10n.caroRuleLastUsed,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        free ? l10n.caroRuleFreeDesc : l10n.caroRuleVnDesc,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          CaroRuleExample(colorX: colorX, colorO: colorO),
                          Text(
                            free
                                ? l10n.caroRuleExampleWin
                                : l10n.caroRuleExampleNoWin,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => Container(
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.textPrimary, width: 2),
    ),
    child: selected
        ? Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}
