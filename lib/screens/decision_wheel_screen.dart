import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/decision.dart';
import '../providers/couple_provider.dart';
import '../providers/decision_provider.dart';
import '../services/analytics_service.dart';
import '../services/decision_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../utils/decision_suggester.dart';
import '../widgets/content_card.dart';
import '../widgets/decision_parts.dart';
import '../widgets/sub_screen_header.dart';

/// "Chọn giúp" — the wheel (feature decision-wheel, design C). Three modes in
/// one screen: Ăn gì · Đi đâu · Tự nhập. Spinning is local (as often as you
/// like, no network); "Chốt luôn" writes once and pops with the written pick
/// so the caller shows the SnackBar.
///
/// The "wheel" is a vertical slot reel: 13 random names + the result, 900ms
/// easeOutCubic. The result is decided BEFORE the reel runs.
class DecisionWheelScreen extends StatefulWidget {
  const DecisionWheelScreen({
    super.key,
    this.initialKind = DecisionKind.eat,
    this.autoSpin = false,
    this.respinOf,
  });

  final DecisionKind initialKind;

  /// Spin once 250ms after opening (from a Spin / Spin-again button, D20).
  final bool autoSpin;

  /// Re-spinning today's pick from the result sheet. For a custom pick this
  /// pre-fills its question + options and "Chốt" updates that same doc.
  final Decision? respinOf;

  @override
  State<DecisionWheelScreen> createState() => _DecisionWheelScreenState();
}

class _DecisionWheelScreenState extends State<DecisionWheelScreen>
    with SingleTickerProviderStateMixin {
  static const double _cell = 128;
  static const int _filler = 13;
  static const Duration _spinDuration = Duration(milliseconds: 900);

  late DecisionKind _kind = widget.initialKind;
  final Map<DecisionKind, String> _filters = {
    DecisionKind.eat: kDecisionFilterAny,
    DecisionKind.go: kDecisionFilterAny,
  };
  final DecisionSuggester _suggester = DecisionSuggester();
  late final AnimationController _reel = AnimationController(
    vsync: this,
    duration: _spinDuration,
  );

  List<String> _reelNames = const <String>[];
  List<String?> _reelEmoji = const <String?>[];
  DecisionCandidate? _result;
  String _via = 'spin';
  int _spinCount = 0;
  bool _spinning = false;
  bool _committing = false;
  bool _commitFailed = false;
  bool _poolEmpty = false;

  // Custom mode.
  final TextEditingController _question = TextEditingController();
  final TextEditingController _optionInput = TextEditingController();
  final FocusNode _questionFocus = FocusNode();
  final FocusNode _optionFocus = FocusNode();
  List<String> _options = <String>[];
  String? _preset; // 'who' | 'which'
  // Brief "already there" / "too long" line under the options (2,5s).
  CustomOptionsIssue? _flashIssue;
  Timer? _duplicateTimer;
  Timer? _hintTimer;
  int _hintIndex = 0;
  String? _existingCustomId;

  @override
  void initState() {
    super.initState();
    final respin = widget.respinOf;
    if (respin != null && respin.kind == DecisionKind.custom) {
      _question.text = respin.question;
      _options = List<String>.of(respin.options);
      _existingCustomId = respin.id;
    }
    _questionFocus.addListener(_syncHintTimer);
    _question.addListener(_syncHintTimer);
    final provider = context.read<DecisionProvider>();
    unawaited(provider.ensureRecent());
    if (widget.autoSpin) {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _spin();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHintTimer();
  }

  @override
  void dispose() {
    _reel.dispose();
    _question.dispose();
    _optionInput.dispose();
    _questionFocus.dispose();
    _optionFocus.dispose();
    _duplicateTimer?.cancel();
    _hintTimer?.cancel();
    super.dispose();
  }

  bool get _reduceMotion => AppMotion.reduceMotion(context);

  // ── Placeholder rotation (custom question) ────────────────────────────────

  void _syncHintTimer() {
    final shouldRun =
        mounted &&
        _kind == DecisionKind.custom &&
        _question.text.isEmpty &&
        !_questionFocus.hasFocus &&
        !_reduceMotion &&
        TickerMode.valuesOf(context).enabled;
    if (shouldRun && _hintTimer == null) {
      _hintTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) setState(() => _hintIndex = (_hintIndex + 1) % 3);
      });
    } else if (!shouldRun && _hintTimer != null) {
      _hintTimer?.cancel();
      _hintTimer = null;
    }
  }

  // ── Spin ────────────────────────────────────────────────────────────────

  bool get _canSpin {
    if (_committing) return false;
    if (_kind == DecisionKind.custom) {
      return validateCustomOptions(_options) == null;
    }
    return !_poolEmpty;
  }

  String _displayName(DecisionCandidate c) => decisionDisplayName(
    _kind,
    c.name,
    c.resultId,
    english: decisionIsEnglish(context),
  );

  Future<void> _spin() async {
    if (_committing) return;
    if (_spinning) {
      _reel.value = 1; // tap while running → jump to the result
      return;
    }
    if (_kind == DecisionKind.custom &&
        validateCustomOptions(_options) != null) {
      return;
    }
    HapticFeedback.selectionClick();
    final provider = context.read<DecisionProvider>();
    final english = decisionIsEnglish(context);
    // First spin of the session waits (briefly) for the 90-day window so the
    // 7/14-day exclusion sees older picks too.
    final history = provider.hasRecent
        ? provider.history
        : await provider.ensureRecent().timeout(
            const Duration(seconds: 2),
            onTimeout: () => provider.history,
          );
    if (!mounted) return;
    final kind = _kind;
    final filter = _filters[kind] ?? '';
    final pick = _suggester.next(
      kind: kind,
      filter: filter,
      history: history,
      english: english,
      options: _options,
    );
    if (pick == null) {
      setState(() {
        _poolEmpty = kind != DecisionKind.custom;
        _result = null;
      });
      return;
    }

    final List<String> names;
    final Map<String, String> emojiByName = {};
    if (kind == DecisionKind.custom) {
      names = _options;
    } else {
      final pool = DecisionSuggester.pool(
        kind: kind,
        filter: filter,
        now: DateTime.now(),
        history: history,
        english: english,
      );
      names = [];
      for (final (c, _) in pool) {
        final shown = _displayName(c);
        names.add(shown);
        if (c.item != null) emojiByName[shown] = c.item!.emoji;
      }
    }
    final filler = _suggester.reelFiller(names, _filler);
    final shownResult = _displayName(pick);

    AnalyticsService.instance.logDecisionSpin(kind: kind.name, filter: filter);
    setState(() {
      _result = pick;
      _via = 'spin';
      _poolEmpty = false;
      _commitFailed = false;
      _reelNames = [...filler, shownResult];
      _reelEmoji = [for (final n in filler) emojiByName[n], pick.item?.emoji];
      _spinning = !_reduceMotion;
    });

    if (_reduceMotion) {
      _reel.value = 1;
      _spinCount++;
      HapticFeedback.mediumImpact();
      return;
    }
    await _reel.forward(from: 0).orCancel.catchError((_) {});
    if (!mounted || _result != pick) return;
    setState(() {
      _spinning = false;
      _spinCount++;
    });
    HapticFeedback.mediumImpact();
  }

  void _setKind(DecisionKind kind) {
    if (kind == _kind || _committing) return;
    HapticFeedback.selectionClick();
    _reel.stop();
    setState(() {
      _kind = kind;
      _result = null;
      _spinning = false;
      _commitFailed = false;
      _poolEmpty = false;
    });
    _syncHintTimer();
  }

  void _setFilter(String filter) {
    if (_committing) return;
    HapticFeedback.selectionClick();
    setState(() {
      _filters[_kind] = filter;
      _poolEmpty = false;
      _commitFailed = false;
    });
  }

  // ── Commit ──────────────────────────────────────────────────────────────

  bool get _customCapBlocks =>
      _kind == DecisionKind.custom &&
      _existingCustomId == null &&
      context.read<DecisionProvider>().customCapReached;

  Future<void> _commit() async {
    final pick = _result;
    if (pick == null || _committing || _spinning || _customCapBlocks) return;
    final l10n = context.l10n;
    setState(() {
      _committing = true;
      _commitFailed = false;
    });
    final provider = context.read<DecisionProvider>();
    try {
      final String question;
      if (_kind == DecisionKind.custom) {
        final typed = _question.text.trim();
        question = typed.isNotEmpty
            ? typed
            : switch (_preset) {
                'who' => l10n.decisionPresetWho,
                'which' => l10n.decisionPresetWhich,
                _ => l10n.decisionCustomDefaultQuestion,
              };
      } else {
        question = '';
      }
      if (decisionTextSize(question) > kDecisionQuestionMax) {
        // The formatter caps typing; this catches anything else (rules
        // would reject it and the user would be stuck on "Thử lại").
        setState(() => _committing = false);
        _flash(CustomOptionsIssue.tooLong);
        _questionFocus.requestFocus();
        return;
      }
      final written = await provider.commit(
        kind: _kind,
        result: pick.name,
        resultId: pick.resultId,
        filter: _kind == DecisionKind.custom ? '' : (_filters[_kind] ?? ''),
        question: question,
        options: _kind == DecisionKind.custom ? _options : const <String>[],
        existingId: _kind == DecisionKind.custom ? _existingCustomId : null,
        via: _via,
        preset: _kind == DecisionKind.custom ? _preset : null,
      );
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop<(Decision, DecisionCommitOutcome)>(written);
    } catch (e) {
      debugPrint('Decision commit failed: $e');
      if (!mounted) return;
      setState(() {
        _committing = false;
        _commitFailed = true;
      });
    }
  }

  Future<void> _openManual() async {
    final text = await showModalBottomSheet<String>(
      context: context,
      routeSettings: const RouteSettings(name: 'DecisionManualSheet'),
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ManualSheet(kind: _kind),
    );
    if (text == null || text.trim().isEmpty || !mounted) return;
    _reel.stop();
    setState(() {
      _result = DecisionCandidate(name: text.trim());
      _via = 'manual';
      _spinning = false;
      _reelNames = [text.trim()];
      _reelEmoji = const <String?>[null];
      _reel.value = 1;
    });
    await _commit();
  }

  // ── Custom options ──────────────────────────────────────────────────────

  void _optionsChanged(List<String> next) {
    setState(() {
      _options = next;
      // The old result may not be an option any more → back to idle.
      _result = null;
      _spinning = false;
      _commitFailed = false;
      // Changed options can't update the original doc (rules pin `options`).
      _existingCustomId = null;
    });
    _reel.stop();
  }

  void _addOption() {
    final text = _optionInput.text.trim();
    if (text.isEmpty) return;
    final next = [..._options, text];
    // Same checks as the rules; a 1-option list is only "too few" so far.
    switch (validateCustomOptions(next)) {
      case final CustomOptionsIssue issue
          when issue != CustomOptionsIssue.tooFew:
        // Never drop the option silently: say why, like the duplicate line.
        _flash(issue);
        return;
      default:
        break;
    }
    HapticFeedback.selectionClick();
    _optionInput.clear();
    _optionsChanged(next);
    _optionFocus.requestFocus();
  }

  void _flash(CustomOptionsIssue issue) {
    _duplicateTimer?.cancel();
    setState(() => _flashIssue = issue);
    _duplicateTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _flashIssue = null);
    });
  }

  /// Clips a preset name to [kDecisionOptionMax] UTF-16 units (rules limit)
  /// without leaving half a surrogate pair at the end.
  static String _clipOption(String name) {
    if (name.length <= kDecisionOptionMax) return name;
    var cut = kDecisionOptionMax;
    final last = name.codeUnitAt(cut - 1);
    if (last >= 0xD800 && last <= 0xDBFF) cut--;
    return name.substring(0, cut).trim();
  }

  void _applyPreset(String preset) {
    HapticFeedback.selectionClick();
    final l10n = context.l10n;
    final previous = List<String>.of(_options);
    final previousPreset = _preset;
    final couple = context.read<CoupleProvider>().couple;
    final next = preset == 'who'
        ? <String>[
            _clipOption(decisionMyName(context, couple)),
            _clipOption(decisionPartnerName(context, couple)),
          ]
        : <String>[];
    _preset = preset;
    _optionsChanged(next);
    if (preset == 'which') _optionFocus.requestFocus();
    if (previous.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            persist: false,
            content: Text(l10n.decisionPresetReplaced(previous.length)),
            action: SnackBarAction(
              label: l10n.customRemindersUndoLabel,
              onPressed: () {
                if (!mounted) return;
                _preset = previousPreset;
                _optionsChanged(previous);
              },
            ),
          ),
        );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.dawnBlush),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: SubScreenHeader(
                  badge: l10n.decisionBadge,
                  badgeIcon: IconsaxPlusLinear.shuffle,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildModeBar(l10n),
                      if (_kind != DecisionKind.custom) ...[
                        const SizedBox(height: 14),
                        _buildFilters(l10n),
                        const SizedBox(height: 16),
                        _buildReelCard(l10n),
                        _buildCurrentLine(l10n),
                      ] else ...[
                        const SizedBox(height: 16),
                        _buildCustomForm(l10n),
                        if (_options.length >= kDecisionOptionsMin) ...[
                          const SizedBox(height: 16),
                          _buildReelCard(l10n),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              _buildActionBar(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeBar(AppLocalizations l10n) {
    const modes = DecisionKind.values;
    final labels = {
      DecisionKind.eat: l10n.decisionModeEat,
      DecisionKind.go: l10n.decisionModeGo,
      DecisionKind.custom: l10n.decisionModeCustom,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        const inset = 4.0;
        final width = (constraints.maxWidth - inset * 2) / modes.length;
        return Container(
          height: 48,
          padding: const EdgeInsets.all(inset),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.white.withValues(alpha: 0.65)),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeInOutCubic,
                left: width * modes.indexOf(_kind),
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final m in modes)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: m == _kind,
                        inMutuallyExclusiveGroup: true,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            splashColor: AppColors.accentRose.withValues(
                              alpha: 0.08,
                            ),
                            highlightColor: Colors.transparent,
                            onTap: () => _setKind(m),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      decisionKindIcon(m, bold: m == _kind),
                                      size: 18,
                                      color: m == _kind
                                          ? AppColors.textPrimary
                                          : AppColors.textPrimary.withValues(
                                              alpha: 0.72,
                                            ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      labels[m]!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: m == _kind
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: m == _kind
                                            ? AppColors.textPrimary
                                            : AppColors.textPrimary.withValues(
                                                alpha: 0.72,
                                              ),
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
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(AppLocalizations l10n) {
    final chips = _kind == DecisionKind.eat
        ? [
            (kDecisionFilterAny, l10n.decisionFilterAny),
            ('nha', l10n.decisionFilterHomeCooked),
            ('ngoai', l10n.decisionFilterEatOut),
            ('nhanh', l10n.decisionFilterQuick),
          ]
        : [
            (kDecisionFilterAny, l10n.decisionFilterAny),
            ('nha', l10n.decisionFilterStayIn),
            ('ngoai', l10n.decisionFilterGoOut),
            ('free', l10n.decisionFilterFree),
          ];
    final current = _filters[_kind];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (id, label) in chips)
          _FilterChip(
            label: label,
            selected: id == current,
            onTap: () => _setFilter(id),
          ),
      ],
    );
  }

  String _reelLabel(AppLocalizations l10n) => switch (_kind) {
    DecisionKind.eat => l10n.decisionReelEatLabel,
    DecisionKind.go => l10n.decisionReelGoLabel,
    DecisionKind.custom => _question.text.trim(),
  };

  Widget _buildReelCard(AppLocalizations l10n) {
    final label = _reelLabel(l10n);
    final pick = _result;
    final tag = pick == null
        ? ''
        : (_via == 'manual'
              ? (_kind == DecisionKind.eat
                    ? l10n.decisionTagManualEat
                    : l10n.decisionTagManualGo)
              : decisionTag(
                  l10n,
                  _kind,
                  resultId: pick.resultId,
                  optionCount: _options.length,
                ));

    Widget body;
    if (pick == null) {
      final idle = _poolEmpty
          ? l10n.decisionPoolEmpty
          : switch (_kind) {
              DecisionKind.eat => l10n.decisionIdleEat,
              DecisionKind.go => l10n.decisionIdleGo,
              DecisionKind.custom => l10n.decisionIdleCustom,
            };
      body = SizedBox(
        height: _cell,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                IconsaxPlusLinear.shuffle,
                size: 28,
                color: AppColors.textPrimary.withValues(alpha: 0.40),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              idle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    } else {
      final shownResult = _reelNames.isEmpty ? pick.name : _reelNames.last;
      body = GestureDetector(
        onTap: _spinning ? () => _reel.value = 1 : null,
        child: _spinning
            ? ExcludeSemantics(child: _buildReel())
            : Semantics(
                liveRegion: true,
                label: l10n.decisionResultSemantics(shownResult, tag),
                excludeSemantics: true,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(_spinCount),
                  tween: Tween(begin: _reduceMotion ? 1 : 0.97, end: 1),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: _buildReel(),
                ),
              ),
      );
    }

    return ContentCard(
      child: Column(
        children: [
          if (label.isNotEmpty) ...[
            Text(
              _kind == DecisionKind.custom ? label : label.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: _kind == DecisionKind.custom ? 14 : 11,
                fontWeight: FontWeight.w700,
                letterSpacing: _kind == DecisionKind.custom ? 0 : 1.2,
              ),
            ),
            const SizedBox(height: 12),
          ],
          body,
          const SizedBox(height: 10),
          AnimatedOpacity(
            opacity: pick != null && !_spinning ? 1 : 0,
            duration: _reduceMotion ? Duration.zero : AppMotion.fast,
            curve: AppMotion.curve,
            child: Text(
              tag,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReel() {
    final count = _reelNames.length;
    return SizedBox(
      height: _cell,
      child: ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, 20 / 128, 108 / 128, 1],
        ).createShader(rect),
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: double.infinity,
            child: AnimatedBuilder(
              animation: _reel,
              builder: (context, child) {
                final t = Curves.easeOutCubic.transform(_reel.value);
                return Transform.translate(
                  offset: Offset(0, -t * (count - 1) * _cell),
                  child: child,
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < count; i++)
                    SizedBox(
                      height: _cell,
                      child: _ReelCell(
                        name: _reelNames[i],
                        emoji: _reelEmoji.length > i ? _reelEmoji[i] : null,
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

  Widget _buildCurrentLine(AppLocalizations l10n) {
    final current = _kind == DecisionKind.eat
        ? context.select<DecisionProvider, Decision?>((p) => p.todayEat)
        : context.select<DecisionProvider, Decision?>((p) => p.todayGo);
    if (current == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        l10n.decisionCurrent(
          decisionDisplayName(
            current.kind,
            current.result,
            current.resultId,
            english: decisionIsEnglish(context),
          ),
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.72),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Custom form ─────────────────────────────────────────────────────────

  Widget _buildCustomForm(AppLocalizations l10n) {
    final hints = [
      l10n.decisionQuestionHint1,
      l10n.decisionQuestionHint2,
      l10n.decisionQuestionHint3,
    ];
    final full = _options.length >= kDecisionOptionsMaxCount;
    final String? helper;
    if (_flashIssue == CustomOptionsIssue.tooLong) {
      helper = l10n.decisionTextTooLong;
    } else if (_flashIssue == CustomOptionsIssue.duplicate ||
        validateCustomOptions(_options) == CustomOptionsIssue.duplicate) {
      // The flash, or a "Ai làm?" preset where both names are the same.
      helper = l10n.decisionOptionDuplicate;
    } else if (full || _flashIssue == CustomOptionsIssue.tooMany) {
      helper = l10n.decisionOptionsMax;
    } else if (_options.length < kDecisionOptionsMin) {
      helper = l10n.decisionOptionsNeedTwo;
    } else {
      helper = null;
    }
    final addHint = _preset == 'which' && _options.length < 2
        ? l10n.decisionOptionNumberHint(_options.length + 1)
        : l10n.decisionOptionAddHint;

    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(l10n.decisionQuestionLabel),
          const SizedBox(height: 8),
          TextField(
            controller: _question,
            focusNode: _questionFocus,
            inputFormatters: const [
              DecisionLengthFormatter(kDecisionQuestionMax),
            ],
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            onChanged: (text) => setState(() {
              // A re-spin can't rewrite the question (rules pin it), so an
              // edited question becomes a NEW pick, like edited options.
              if (text.trim() != widget.respinOf?.question.trim()) {
                _existingCustomId = null;
              }
            }),
            onSubmitted: (_) => _optionFocus.requestFocus(),
            buildCounter:
                (_, {required currentLength, required isFocused, maxLength}) =>
                    decisionLengthCounter(_question.text, kDecisionQuestionMax),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: _fieldDecoration(
              _reduceMotion ? hints.first : hints[_hintIndex],
            ),
          ),
          const SizedBox(height: 12),
          _FieldLabel(l10n.decisionPresetLabel),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ActionChip(
                icon: IconsaxPlusLinear.profile_2user,
                label: l10n.decisionPresetWho,
                onTap: () => _applyPreset('who'),
              ),
              _ActionChip(
                icon: IconsaxPlusLinear.task_square,
                label: l10n.decisionPresetWhich,
                onTap: () => _applyPreset('which'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _FieldLabel(l10n.decisionOptionsLabel)),
              Text(
                l10n.decisionOptionsCount(_options.length),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSize(
            duration: AppMotion.fast,
            curve: AppMotion.curve,
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _options.length; i++)
                  _ValueChip(
                    key: ValueKey('opt-${_options[i]}'),
                    label: _options[i],
                    removeLabel: l10n.decisionOptionRemove(_options[i]),
                    onEdit: () {
                      final text = _options[i];
                      _optionsChanged([..._options]..removeAt(i));
                      _optionInput.text = text;
                      _optionFocus.requestFocus();
                    },
                    onRemove: () {
                      HapticFeedback.selectionClick();
                      _optionsChanged([..._options]..removeAt(i));
                    },
                  ),
              ],
            ),
          ),
          if (!full) ...[
            if (_options.isNotEmpty) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optionInput,
                    focusNode: _optionFocus,
                    inputFormatters: const [
                      DecisionLengthFormatter(kDecisionOptionMax),
                    ],
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _addOption(),
                    buildCounter:
                        (
                          _, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _fieldDecoration(addHint),
                  ),
                ),
                const SizedBox(width: 8),
                Semantics(
                  button: true,
                  label: l10n.decisionOptionAdd,
                  child: Material(
                    color: _optionInput.text.trim().isEmpty
                        ? AppColors.textPrimary.withValues(alpha: 0.28)
                        : AppColors.textPrimary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _optionInput.text.trim().isEmpty
                          ? null
                          : _addOption,
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          IconsaxPlusLinear.add,
                          size: 20,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (helper != null) ...[
            const SizedBox(height: 10),
            _HelperLine(helper),
          ],
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
    filled: true,
    fillColor: AppColors.surfaceLight,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
  );

  // ── Action bar ──────────────────────────────────────────────────────────

  Widget _buildActionBar(AppLocalizations l10n) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final spinSemantics = switch (_kind) {
      DecisionKind.eat => l10n.decisionSpinSemanticsEat,
      DecisionKind.go => l10n.decisionSpinSemanticsGo,
      DecisionKind.custom => l10n.decisionSpinSemanticsCustom,
    };
    final hasResult = _result != null && !_spinning;
    final capBlocks = _customCapBlocks;

    final Widget buttons;
    if (!hasResult) {
      buttons = DecisionPillButton(
        key: const ValueKey('spin'),
        label: l10n.decisionSpin,
        icon: IconsaxPlusLinear.shuffle,
        semanticsLabel: spinSemantics,
        onPressed: _spinning || _canSpin ? _spin : null,
      );
    } else {
      buttons = Row(
        key: const ValueKey('commit'),
        children: [
          Expanded(
            flex: 2,
            child: DecisionPillButton(
              primary: false,
              onBlush: true,
              label: l10n.decisionRespin,
              icon: IconsaxPlusLinear.refresh,
              semanticsLabel: spinSemantics,
              onPressed: _committing || !_canSpin ? null : _spin,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: DecisionPillButton(
              label: _commitFailed ? l10n.decisionRetry : l10n.decisionCommit,
              icon: _commitFailed
                  ? IconsaxPlusLinear.refresh
                  : IconsaxPlusLinear.tick_circle,
              busy: _committing,
              onPressed: capBlocks ? null : _commit,
            ),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_commitFailed) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    IconsaxPlusLinear.cloud_cross,
                    size: 18,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.decisionCommitFailed,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (capBlocks && hasResult) ...[
            _HelperLine(l10n.decisionCustomDailyCap),
            const SizedBox(height: 10),
          ],
          AnimatedSwitcher(
            duration: AppMotion.fast,
            switchInCurve: AppMotion.curve,
            child: buttons,
          ),
          if (_kind != DecisionKind.custom)
            DecisionLinkButton(
              label: l10n.decisionManual,
              icon: IconsaxPlusLinear.edit_2,
              onPressed: _committing ? null : _openManual,
            ),
        ],
      ),
    );
  }
}

class _ReelCell extends StatelessWidget {
  const _ReelCell({required this.name, this.emoji});

  final String name;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
          ],
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width - 88,
                ),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: AppMotion.fast,
              curve: AppMotion.curve,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.white.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.white.withValues(alpha: 0.65),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    const Icon(
                      IconsaxPlusBold.tick_circle,
                      size: 14,
                      color: AppColors.white,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppColors.white : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: AppColors.accentRose.withValues(alpha: 0.08),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.textPrimary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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

class _ValueChip extends StatelessWidget {
  const _ValueChip({
    super.key,
    required this.label,
    required this.removeLabel,
    required this.onEdit,
    required this.onRemove,
  });

  final String label;
  final String removeLabel;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.accentRose.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: removeLabel,
            excludeSemantics: true,
            child: InkResponse(
              onTap: onRemove,
              radius: 20,
              child: const SizedBox(
                width: 44,
                height: 40,
                child: Icon(
                  IconsaxPlusLinear.close_circle,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    ),
  );
}

class _HelperLine extends StatelessWidget {
  const _HelperLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(
          IconsaxPlusLinear.info_circle,
          size: 14,
          color: AppColors.textPrimary.withValues(alpha: 0.55),
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.textPrimary.withValues(alpha: 0.72),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

/// Sheet "Nhập tay" (design C2): type your own dish / plan (≤40) and lock it
/// in without spinning. Pops the text.
class _ManualSheet extends StatefulWidget {
  const _ManualSheet({required this.kind});

  final DecisionKind kind;

  @override
  State<_ManualSheet> createState() => _ManualSheetState();
}

class _ManualSheetState extends State<_ManualSheet> {
  final TextEditingController _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _text.text.trim();
    if (value.isEmpty || decisionTextSize(value) > kDecisionResultMax) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eat = widget.kind == DecisionKind.eat;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              eat ? l10n.decisionManualTitleEat : l10n.decisionManualTitleGo,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _text,
              autofocus: true,
              inputFormatters: const [
                DecisionLengthFormatter(kDecisionResultMax),
              ],
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => decisionLengthCounter(
                    _text.text,
                    kDecisionResultMax,
                    left: kDecisionResultMax,
                  ),
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: eat
                    ? l10n.decisionManualHintEat
                    : l10n.decisionManualHintGo,
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surfaceLight,
                counterStyle: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            DecisionPillButton(
              label: l10n.decisionCommit,
              icon: IconsaxPlusLinear.tick_circle,
              onPressed: _text.text.trim().isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
