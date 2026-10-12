import 'dart:async';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/chat_message.dart';
import '../models/daily_answer.dart';
import '../models/mood.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/daily_question_provider.dart';
import '../providers/mood_provider.dart';
import '../providers/sleep_provider.dart';
import '../services/daily_question_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/person_palette.dart';
import 'mood_card.dart' show moodLabel;

/// Love Tree v3 (2026-10-11) — "bầu trời = hôm nay". Each partner has three
/// stars for three small things done today; the heart outline closes only when
/// both chip in. Computed on the client from streams the app already runs
/// (daily answers, moods, chat) — no new data, no backend.
enum CareTask { question, mood, message }

class CareStar {
  const CareStar({required this.lit, this.at, this.moodKey});

  final bool lit;

  /// When it happened (null when unknown, e.g. a write still pending).
  final DateTime? at;

  /// The mood picked today (mood star only).
  final String? moodKey;
}

class TodayConstellation {
  const TodayConstellation({required this.mine, required this.partner});

  /// Left half.
  final Map<CareTask, CareStar> mine;

  /// Right half.
  final Map<CareTask, CareStar> partner;

  CareStar star(bool isMine, CareTask task) =>
      (isMine ? mine : partner)[task] ?? const CareStar(lit: false);

  bool lit(bool isMine, CareTask task) => star(isMine, task).lit;

  int get litCount =>
      [...mine.values, ...partner.values].where((s) => s.lit).length;

  bool get isFull => litCount == 6;

  /// The 8 outline segments in drawing order dip → my question → my mood → my
  /// message → tip → their message → their mood → their question → dip. The
  /// top lights when BOTH answered, the bottom when both messaged, each side
  /// when two neighbouring stars of the same person are lit — so the heart
  /// only closes when both of them chip in.
  List<bool> get segments {
    final q = lit(true, CareTask.question) && lit(false, CareTask.question);
    final m = lit(true, CareTask.message) && lit(false, CareTask.message);
    bool side(bool isMine, CareTask a, CareTask b) =>
        lit(isMine, a) && lit(isMine, b);
    return [
      q,
      side(true, CareTask.question, CareTask.mood),
      side(true, CareTask.mood, CareTask.message),
      m,
      m,
      side(false, CareTask.message, CareTask.mood),
      side(false, CareTask.mood, CareTask.question),
      q,
    ];
  }

  /// Reads today's state from the live providers (rebuilds with them).
  static TodayConstellation watch(BuildContext context) {
    final dq = context.watch<DailyQuestionProvider>();
    final mood = context.watch<MoodProvider>();
    return from(
      myUid: context.read<AuthProvider>().currentUser?.id,
      now: DateTime.now(),
      questionDay: dq.dateKey,
      myAnswer: dq.myAnswer,
      partnerAnswer: dq.partnerAnswer,
      myMood: mood.myMood,
      partnerMood: mood.partnerMood,
      messages: context.watch<ChatProvider>().messages,
    );
  }

  /// Pure core of [watch]. [questionDay] is the day the answers belong to:
  /// the provider only moves to a new day when Home re-arms it, so past 0:00
  /// it can still hold yesterday's answers — those must not light today.
  static TodayConstellation from({
    required String? myUid,
    required DateTime now,
    required String questionDay,
    DailyAnswer? myAnswer,
    DailyAnswer? partnerAnswer,
    Mood? myMood,
    Mood? partnerMood,
    List<ChatMessage> messages = const [],
  }) {
    bool isToday(DateTime t) {
      final l = t.toLocal();
      return l.year == now.year && l.month == now.month && l.day == now.day;
    }

    // Newest message of today per side (messages are newest-first; a pending
    // message has no server time yet but was obviously sent just now).
    CareStar? myMsg;
    CareStar? theirMsg;
    for (final msg in messages) {
      final at = msg.createdAt ?? (msg.isPending ? now : null);
      if (at == null || !isToday(at)) {
        continue;
      }
      if (msg.authorUserId == myUid) {
        myMsg ??= CareStar(lit: true, at: at);
      } else {
        theirMsg ??= CareStar(lit: true, at: at);
      }
      if (myMsg != null && theirMsg != null) {
        break;
      }
    }

    final questionToday = questionDay == DailyQuestionService.dateKey(now);
    const off = CareStar(lit: false);
    return TodayConstellation(
      mine: {
        CareTask.question: questionToday && myAnswer?.hasText == true
            ? CareStar(lit: true, at: myAnswer!.answeredAt)
            : off,
        CareTask.mood: myMood == null
            ? off
            : CareStar(lit: true, at: myMood.updatedAt, moodKey: myMood.mood),
        CareTask.message: myMsg ?? off,
      },
      partner: {
        CareTask.question: questionToday && partnerAnswer != null
            ? CareStar(lit: true, at: partnerAnswer.answeredAt)
            : off,
        CareTask.mood: partnerMood == null
            ? off
            : CareStar(
                lit: true,
                at: partnerMood.updatedAt,
                moodKey: partnerMood.mood,
              ),
        CareTask.message: theirMsg ?? off,
      },
    );
  }
}

/// Rebuilds [builder] at every local midnight — "today" rolls over even when
/// no provider changes — and on app resume, since a timer can run late while
/// the device sleeps.
class MidnightBuilder extends StatefulWidget {
  const MidnightBuilder({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  State<MidnightBuilder> createState() => _MidnightBuilderState();
}

class _MidnightBuilderState extends State<MidnightBuilder>
    with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _arm();
  }

  void _arm() {
    _timer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    _timer = Timer(midnight.difference(now), _roll);
  }

  void _roll() {
    if (!mounted) {
      return;
    }
    setState(() {});
    _arm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _roll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

// Geometry of the 260×216 heart (design v3 §3), shared by the big view and the
// Home pill's mini icon.
const Size _kBox = Size(260, 216);
const Offset _kDip = Offset(130, 66);
const Offset _kTip = Offset(130, 206);
const Map<CareTask, Offset> _kMine = {
  CareTask.question: Offset(70, 40),
  CareTask.mood: Offset(30, 104),
  CareTask.message: Offset(82, 162),
};
const Map<CareTask, Offset> _kPartner = {
  CareTask.question: Offset(190, 40),
  CareTask.mood: Offset(230, 104),
  CareTask.message: Offset(178, 162),
};

/// Outline points in drawing order (see [TodayConstellation.segments]).
const List<Offset> _kOutline = [
  _kDip,
  Offset(70, 40),
  Offset(30, 104),
  Offset(82, 162),
  _kTip,
  Offset(178, 162),
  Offset(230, 104),
  Offset(190, 40),
];

const Color _kStarCream = Color(0xFFFFF6D6);
const Color _kHeartFill = Color(0xFFFF8FA3);

/// A 4-point sparkle centred in [size].
Path _sparklePath(Offset c, double r) {
  const k = 0.16;
  return Path()
    ..moveTo(c.dx, c.dy - r)
    ..quadraticBezierTo(c.dx + r * k, c.dy - r * k, c.dx + r, c.dy)
    ..quadraticBezierTo(c.dx + r * k, c.dy + r * k, c.dx, c.dy + r)
    ..quadraticBezierTo(c.dx - r * k, c.dy + r * k, c.dx - r, c.dy)
    ..quadraticBezierTo(c.dx - r * k, c.dy - r * k, c.dx, c.dy - r)
    ..close();
}

String _taskTitle(AppLocalizations l10n, CareTask t) => switch (t) {
  CareTask.question => l10n.loveTreeTaskQuestion,
  CareTask.mood => l10n.loveTreeTaskMood,
  CareTask.message => l10n.loveTreeTaskMessage,
};

String _starLabel(AppLocalizations l10n, CareTask t) => switch (t) {
  CareTask.question => l10n.loveTreeStarQuestion,
  CareTask.mood => l10n.loveTreeStarMood,
  CareTask.message => l10n.loveTreeStarMessage,
};

/// A crisp outline in the sky's colour around a star label: it cuts the
/// heart's line where it runs under the letters ("Tâm trạng" sits on it).
const List<Shadow> _kLabelOutline = [
  Shadow(color: _kLabelSky, offset: Offset(1.4, 0), blurRadius: 0.6),
  Shadow(color: _kLabelSky, offset: Offset(-1.4, 0), blurRadius: 0.6),
  Shadow(color: _kLabelSky, offset: Offset(0, 1.4), blurRadius: 0.6),
  Shadow(color: _kLabelSky, offset: Offset(0, -1.4), blurRadius: 0.6),
  Shadow(color: _kLabelSky, offset: Offset(1, 1), blurRadius: 0.6),
  Shadow(color: _kLabelSky, offset: Offset(-1, 1), blurRadius: 0.6),
  Shadow(color: _kLabelSky, offset: Offset(1, -1), blurRadius: 0.6),
  Shadow(color: _kLabelSky, offset: Offset(-1, -1), blurRadius: 0.6),
];
const Color _kLabelSky = Color(0xFF2E2A52);

/// The night-sky block of the Love Tree: the 6-star heart, its title + count,
/// a one-line explanation, the halves legend and a detail panel for the tapped
/// star (with "do it now" for my own unlit stars, "send some care" for theirs).
class TodayConstellationSection extends StatefulWidget {
  const TodayConstellationSection({
    super.key,
    required this.partnerName,
    required this.onAct,
    required this.onNudge,
  });

  final String partnerName;

  /// One of my unlit stars was acted on.
  final void Function(CareTask task) onAct;

  /// "Gửi lời quan tâm" for one of my partner's unlit stars.
  final VoidCallback onNudge;

  @override
  State<TodayConstellationSection> createState() =>
      _TodayConstellationSectionState();
}

class _TodayConstellationSectionState extends State<TodayConstellationSection> {
  ({bool mine, CareTask task})? _selected;

  @override
  Widget build(BuildContext context) => MidnightBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final sky = TodayConstellation.watch(context);
    final sleep = context.watch<SleepProvider>();
    final myGlow = PersonPalette.onSky(PersonPalette.colorOf(sleep.myColorId));
    final partnerGlow = PersonPalette.onSky(
      PersonPalette.colorOf(sleep.partnerColorId),
    );
    final reduce = AppMotion.reduceMotion(context);

    Widget starButton(bool mine, CareTask task) {
      final pos = (mine ? _kMine : _kPartner)[task]!;
      final isLit = sky.lit(mine, task);
      final selected = _selected?.mine == mine && _selected?.task == task;
      final who = mine ? l10n.reactionYouLabel : widget.partnerName;
      void toggle() {
        HapticFeedback.selectionClick();
        setState(() => _selected = selected ? null : (mine: mine, task: task));
      }

      return Positioned(
        left: pos.dx - 22,
        top: pos.dy - 22,
        child: Semantics(
          button: true,
          selected: selected,
          label: l10n.loveTreeStarSemantics(
            who,
            _taskTitle(l10n, task),
            isLit ? l10n.loveTreeStarLit : l10n.loveTreeStarUnlit,
          ),
          excludeSemantics: true,
          onTap: toggle,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: toggle,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.75)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: CustomPaint(
                painter: _StarPainter(
                  lit: isLit,
                  glow: mine ? myGlow : partnerGlow,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Beside the star, except the mood stars: they sit near the box edges, so
    // theirs goes under the star — centred on it, kept inside the box.
    Widget label(bool mine, CareTask task) {
      final pos = (mine ? _kMine : _kPartner)[task]!;
      final text = ExcludeSemantics(
        child: Text(
          _starLabel(l10n, task),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: sky.lit(mine, task)
                ? AppColors.white
                : AppColors.white.withValues(alpha: 0.72),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            height: 16 / 12,
            shadows: _kLabelOutline,
          ),
        ),
      );
      if (task != CareTask.mood) {
        return Positioned(
          left: mine ? null : pos.dx + 24,
          right: mine ? _kBox.width - pos.dx + 24 : null,
          top: pos.dy - 8,
          child: text,
        );
      }
      final edge = mine ? pos.dx : _kBox.width - pos.dx;
      return Positioned(
        left: mine ? 0 : null,
        right: mine ? null : 0,
        top: pos.dy + 22,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: edge * 2,
            maxWidth: _kBox.width,
          ),
          child: text,
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          width: _kBox.width,
          height: _kBox.height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _HeartPainter(
                    segments: sky.segments,
                    full: sky.isFull,
                  ),
                ),
              ),
              for (final t in CareTask.values) ...[
                label(true, t),
                label(false, t),
              ],
              for (final t in CareTask.values) ...[
                starButton(true, t),
                starButton(false, t),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                l10n.loveTreeSkyTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.26),
                ),
              ),
              child: Text(
                '${sky.litCount}/6',
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Text(
            l10n.loveTreeSkyExplain,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.white.withValues(alpha: 0.88),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 4,
          children: [
            _LegendItem(color: myGlow, text: l10n.loveTreeLeftHalf),
            _LegendItem(
              color: partnerGlow,
              text: l10n.loveTreeRightHalf(widget.partnerName),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 76),
          child: Center(
            child: AnimatedSwitcher(
              duration: reduce ? Duration.zero : AppMotion.fast,
              child: _detail(context, sky, myGlow, partnerGlow),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detail(
    BuildContext context,
    TodayConstellation sky,
    Color myGlow,
    Color partnerGlow,
  ) {
    final l10n = context.l10n;
    final sel = _selected;
    if (sel == null) {
      return sky.isFull
          ? Row(
              key: const ValueKey('full'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox.square(
                  dimension: 16,
                  child: CustomPaint(
                    painter: _StarPainter(lit: true, glow: _kStarCream),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    l10n.loveTreeHeartFull,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          : Row(
              key: const ValueKey('hint'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  IconsaxPlusLinear.finger_cricle,
                  size: 14,
                  color: AppColors.white.withValues(alpha: 0.76),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.loveTreeTapStar,
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.76),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
    }

    final star = sky.star(sel.mine, sel.task);
    final who = sel.mine ? l10n.reactionYouLabel : widget.partnerName;
    final locale = Localizations.localeOf(context).toString();
    final time = star.at == null
        ? ''
        : DateFormat.Hm(locale).format(star.at!.toLocal());
    final String sub;
    if (!star.lit) {
      sub = switch (sel.task) {
        CareTask.question => l10n.loveTreeStarNoAnswer,
        CareTask.mood => l10n.loveTreeStarNoMood,
        CareTask.message => l10n.loveTreeStarNoMessage,
      };
    } else if (sel.task == CareTask.mood) {
      // An unknown key (a newer app's mood) has no label: show just the time.
      final mood = star.moodKey == null ? '' : moodLabel(l10n, star.moodKey!);
      sub = mood.isEmpty
          ? (time.isEmpty ? l10n.loveTreeStarDone : time)
          : (time.isEmpty ? mood : l10n.loveTreeStarMoodAt(mood, time));
    } else if (time.isEmpty) {
      sub = l10n.loveTreeStarDone;
    } else {
      sub = sel.task == CareTask.question
          ? l10n.loveTreeStarAnsweredAt(who, time)
          : l10n.loveTreeStarMessagedAt(who, time);
    }

    Widget? action;
    if (!star.lit && sel.mine) {
      action = _PanelButton(
        filled: true,
        label: switch (sel.task) {
          CareTask.question => l10n.loveTreeActAnswer,
          CareTask.mood => l10n.loveTreeActMood,
          CareTask.message => l10n.loveTreeActMessage,
        },
        onTap: () => widget.onAct(sel.task),
      );
    } else if (!star.lit) {
      action = _PanelButton(
        filled: false,
        label: l10n.loveTreeNudge,
        onTap: widget.onNudge,
      );
    }

    void close() => setState(() => _selected = null);
    return Container(
      key: ValueKey('${sel.mine}-${sel.task}'),
      padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: sel.mine ? myGlow : partnerGlow,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$who · ${_taskTitle(l10n, sel.task)}',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub,
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (action != null) ...[const SizedBox(width: 8), action],
          Semantics(
            button: true,
            label: l10n.loveTreeClosePanel,
            excludeSemantics: true,
            onTap: close,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: close,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  IconsaxPlusLinear.close_circle,
                  size: 18,
                  color: AppColors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.white.withValues(alpha: 0.84),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({
    required this.filled,
    required this.label,
    required this.onTap,
  });

  final bool filled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.white : Colors.transparent,
      shape: StadiumBorder(
        side: filled
            ? BorderSide.none
            : BorderSide(color: AppColors.white.withValues(alpha: 0.55)),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: filled ? AppColors.textPrimary : AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// One star: lit = cream sparkle with a soft glow in the person's colour;
/// unlit = a small outlined sparkle.
class _StarPainter extends CustomPainter {
  const _StarPainter({required this.lit, required this.glow});

  final bool lit;
  final Color glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.shortestSide;
    if (!lit) {
      canvas.drawPath(
        _sparklePath(c, base * 0.2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = AppColors.white.withValues(alpha: 0.62),
      );
      return;
    }
    final r = base >= 40 ? 13.0 : base / 2;
    canvas.drawPath(
      _sparklePath(c, r),
      Paint()
        ..color = glow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    canvas.drawPath(_sparklePath(c, r), Paint()..color = _kStarCream);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.lit != lit || old.glow != glow;
}

/// The heart outline: lit segments solid cream, unlit ones faint dashes; a
/// soft pink fill + a sparkle at the tip once all six stars are lit.
class _HeartPainter extends CustomPainter {
  const _HeartPainter({required this.segments, required this.full});

  final List<bool> segments;
  final bool full;

  @override
  void paint(Canvas canvas, Size size) {
    if (full) {
      canvas.drawPath(
        Path()..addPolygon(_kOutline, true),
        Paint()..color = _kHeartFill.withValues(alpha: 0.24),
      );
    }
    final litPaint = Paint()
      ..color = _kStarCream.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final dimPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.22)
      ..strokeWidth = 1;
    for (var i = 0; i < _kOutline.length; i++) {
      final a = _kOutline[i];
      final b = _kOutline[(i + 1) % _kOutline.length];
      if (segments[i]) {
        canvas.drawLine(a, b, litPaint);
      } else {
        _dashed(canvas, a, b, dimPaint);
      }
    }
    if (full) {
      canvas.drawPath(_sparklePath(_kTip, 7), Paint()..color = _kStarCream);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 3.0;
    const gap = 5.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    for (var d = 0.0; d < total; d += dash + gap) {
      final end = (d + dash).clamp(0.0, total);
      canvas.drawLine(a + dir * d, a + dir * end, paint);
    }
  }

  @override
  bool shouldRepaint(_HeartPainter old) =>
      old.full != full || !listEquals(old.segments, segments);
}

/// Home entry under "Hôm nay của chúng mình": a mini heart of dots + "4/6" —
/// opens the Love Tree. The full sentence is the semantics label.
class ConstellationPill extends StatelessWidget {
  const ConstellationPill({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MidnightBuilder(builder: _build);

  Widget _build(BuildContext context) {
    final l10n = context.l10n;
    final sky = TodayConstellation.watch(context);
    final sleep = context.watch<SleepProvider>();
    void open() {
      HapticFeedback.selectionClick();
      onTap();
    }

    return Semantics(
      button: true,
      label: l10n.homeConstellationSemantics(sky.litCount),
      excludeSemantics: true,
      onTap: open,
      child: Material(
        color: AppColors.white.withValues(alpha: 0.72),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.65)),
        ),
        shadowColor: AppColors.accentRose.withValues(alpha: 0.28),
        elevation: 2,
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: open,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 20,
                  child: CustomPaint(
                    painter: _MiniHeartPainter(
                      sky: sky,
                      mine: PersonPalette.colorOf(sleep.myColorId),
                      partner: PersonPalette.colorOf(sleep.partnerColorId),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '${sky.litCount}/6',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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

class _MiniHeartPainter extends CustomPainter {
  const _MiniHeartPainter({
    required this.sky,
    required this.mine,
    required this.partner,
  });

  final TodayConstellation sky;
  final Color mine;
  final Color partner;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _kBox.width;
    final sy = size.height / _kBox.height;
    Offset map(Offset p) => Offset(p.dx * sx, p.dy * sy);
    canvas.drawPath(
      Path()..addPolygon([for (final p in _kOutline) map(p)], true),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.textPrimary.withValues(alpha: 0.22),
    );
    void dot(Offset p, bool isLit, Color color) {
      final c = map(p);
      if (isLit) {
        canvas.drawCircle(c, 2.6, Paint()..color = color);
      } else {
        canvas.drawCircle(
          c,
          2.1,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = color,
        );
      }
    }

    for (final t in CareTask.values) {
      dot(_kMine[t]!, sky.lit(true, t), mine);
      dot(_kPartner[t]!, sky.lit(false, t), partner);
    }
  }

  @override
  bool shouldRepaint(_MiniHeartPainter old) => true; // 6 dots, trivial
}
