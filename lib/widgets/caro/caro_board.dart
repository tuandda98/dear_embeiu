import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../models/caro_game.dart';
import '../../theme/app_colors.dart';

/// Two-step tap on the board (caro-game design C5): the first tap on an empty
/// square selects it (faded stone), a second tap on the SAME square plays it —
/// but only once [confirmDelay] has passed, so two quick accidental taps never
/// become a move. Tapping another square moves the selection. Pure.
enum CaroTapResult { selected, play, ignored }

class CaroTapSelector {
  CaroTapSelector({this.confirmDelay = const Duration(milliseconds: 400)});

  final Duration confirmDelay;

  int? _selected;
  DateTime? _selectedAt;

  int? get selected => _selected;

  /// [cell] must already be a legal empty square (the screen checks turn /
  /// occupancy / sending before calling).
  CaroTapResult tap(int cell, DateTime now) {
    if (_selected == cell) {
      final at = _selectedAt;
      if (at != null && now.difference(at) >= confirmDelay) {
        return CaroTapResult.play;
      }
      return CaroTapResult.ignored;
    }
    _selected = cell;
    _selectedAt = now;
    return CaroTapResult.selected;
  }

  void clear() {
    _selected = null;
    _selectedAt = null;
  }
}

/// Zoom matrix for the board (design C4): [scale] around [focusCell] (the last
/// move), clamped so the board never leaves its frame. `scale <= 1` or no
/// focus → identity / centred.
Matrix4 caroZoomMatrix(double side, double scale, int? focusCell) {
  if (scale <= 1 || side <= 0) {
    return Matrix4.identity();
  }
  final cell = side / CaroBoard.size;
  final focus = focusCell ?? CaroBoard.indexOf(7, 7);
  final cx = (CaroBoard.colOf(focus) + 0.5) * cell;
  final cy = (CaroBoard.rowOf(focus) + 0.5) * cell;
  final minT = side - side * scale;
  final tx = (side / 2 - cx * scale).clamp(minT, 0.0);
  final ty = (side / 2 - cy * scale).clamp(minT, 0.0);
  return Matrix4.identity()
    ..translateByDouble(tx, ty, 0, 1)
    ..scaleByDouble(scale, scale, 1, 1);
}

/// Draws one stone (X = two diagonals, O = ring) centred at [c] in a square
/// of side [cell] (design §3.3).
void paintCaroStone(
  Canvas canvas,
  Offset c,
  double cell,
  CaroSide side,
  Color color, {
  double scale = 1,
}) {
  final stroke = math.max(2.2, cell * 0.11) * scale;
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round;
  if (side == CaroSide.x) {
    final a = cell * 0.26 * scale;
    canvas.drawLine(c + Offset(-a, -a), c + Offset(a, a), paint);
    canvas.drawLine(c + Offset(a, -a), c + Offset(-a, a), paint);
  } else {
    canvas.drawCircle(c, cell * 0.28 * scale, paint);
  }
}

/// The 15×15 grid ("ô ly"), stones in the players' own colours, last move
/// tinted, the selected square and the winning run (design §3.3). Shared by
/// the live game, the result and the replay.
class CaroBoardPainter extends CustomPainter {
  CaroBoardPainter({
    required this.board,
    required this.colorX,
    required this.colorO,
    this.selected,
    this.selectedSide = CaroSide.x,
    this.sending = false,
    this.winLine = const <int>[],
    this.winProgress = 1,
    this.dropCell,
    this.dropProgress = 1,
    this.lineWidth = 1,
    this.semanticsLabelOf,
    this.semanticsTapOf,
    super.repaint,
  });

  final CaroBoard board;
  final Color colorX;
  final Color colorO;
  final int? selected;
  final CaroSide selectedSide;
  final bool sending;
  final List<int> winLine;
  final double winProgress;
  final int? dropCell;
  final double dropProgress;

  /// Grid stroke in scene units (the caller divides by zoom × dpr so the line
  /// stays 1 physical pixel).
  final double lineWidth;

  final String Function(int index)? semanticsLabelOf;
  final VoidCallback? Function(int index)? semanticsTapOf;

  Color _colorOf(CaroSide side) => side == CaroSide.x ? colorX : colorO;

  Offset _center(int index, double cell) => Offset(
    (CaroBoard.colOf(index) + 0.5) * cell,
    (CaroBoard.rowOf(index) + 0.5) * cell,
  );

  Rect _rect(int index, double cell) => Rect.fromLTWH(
    CaroBoard.colOf(index) * cell,
    CaroBoard.rowOf(index) * cell,
    cell,
    cell,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / CaroBoard.size;
    final grid = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.12)
      ..strokeWidth = lineWidth;
    for (var i = 1; i < CaroBoard.size; i++) {
      final d = i * cell;
      canvas.drawLine(Offset(d, 0), Offset(d, size.height), grid);
      canvas.drawLine(Offset(0, d), Offset(size.width, d), grid);
    }

    // Winning run under the stones.
    final winner = winLine.isEmpty ? null : board.pieceAt(winLine.first);
    if (winner != null && winProgress > 0) {
      final tint = Paint()..color = _colorOf(winner).withValues(alpha: 0.16);
      for (final i in winLine) {
        canvas.drawRect(_rect(i, cell), tint);
      }
      final a = _center(winLine.first, cell);
      final b = _center(winLine.last, cell);
      canvas.drawLine(
        a,
        Offset.lerp(a, b, winProgress.clamp(0, 1))!,
        Paint()
          ..color = _colorOf(winner).withValues(alpha: 0.30)
          ..strokeWidth = cell * 0.55
          ..strokeCap = StrokeCap.round,
      );
    } else if (board.cells.isNotEmpty) {
      // Last move: the mover's colour behind the stone.
      final last = board.cells.last;
      final side = board.pieceAt(last)!;
      canvas.drawRect(
        _rect(last, cell),
        Paint()..color = _colorOf(side).withValues(alpha: 0.16),
      );
    }

    for (var n = 0; n < board.cells.length; n++) {
      final index = board.cells[n];
      final side = n.isEven ? CaroSide.x : CaroSide.o;
      final dropping = index == dropCell && dropProgress < 1;
      final t = dropping ? dropProgress.clamp(0.0, 1.0) : 1.0;
      paintCaroStone(
        canvas,
        _center(index, cell),
        cell,
        side,
        _colorOf(side).withValues(alpha: t),
        scale: dropping ? 0.6 + 0.4 * t : 1,
      );
    }

    final sel = selected;
    if (sel != null && board.isEmpty(sel)) {
      final r = _rect(sel, cell).deflate(1.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()
          ..color = AppColors.textPrimary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      paintCaroStone(
        canvas,
        _center(sel, cell),
        cell,
        selectedSide,
        _colorOf(selectedSide).withValues(alpha: sending ? 0.60 : 0.45),
      );
    }
  }

  @override
  SemanticsBuilderCallback? get semanticsBuilder {
    final labelOf = semanticsLabelOf;
    if (labelOf == null) {
      return null;
    }
    return (Size size) {
      final cell = size.width / CaroBoard.size;
      return <CustomPainterSemantics>[
        for (var i = 0; i < CaroBoard.squares; i++)
          CustomPainterSemantics(
            key: ValueKey<int>(i),
            rect: _rect(i, cell),
            properties: SemanticsProperties(
              label: labelOf(i),
              button: semanticsTapOf?.call(i) != null,
              onTap: semanticsTapOf?.call(i),
              textDirection: TextDirection.ltr,
            ),
          ),
      ];
    };
  }

  @override
  bool shouldRebuildSemantics(CaroBoardPainter oldDelegate) =>
      oldDelegate.board.cells.length != board.cells.length ||
      oldDelegate.selected != selected ||
      oldDelegate.winLine.length != winLine.length ||
      oldDelegate.semanticsTapOf != semanticsTapOf;

  @override
  bool shouldRepaint(CaroBoardPainter oldDelegate) =>
      oldDelegate.board.cells.length != board.cells.length ||
      oldDelegate.selected != selected ||
      oldDelegate.sending != sending ||
      oldDelegate.winProgress != winProgress ||
      oldDelegate.dropProgress != dropProgress ||
      oldDelegate.dropCell != dropCell ||
      oldDelegate.colorX != colorX ||
      oldDelegate.colorO != colorO ||
      oldDelegate.lineWidth != lineWidth ||
      oldDelegate.winLine.length != winLine.length;
}

/// 26px caro badge (design §0): a faint cross, my X and the partner's O in
/// our own colours. Sits on a 44 r16 `surfaceLight` square like `IconBadge`.
class CaroGlyph extends StatelessWidget {
  const CaroGlyph({
    super.key,
    required this.mine,
    required this.partner,
    this.size = 44,
    this.showDot = false,
  });

  final Color mine;
  final Color partner;
  final double size;

  /// The 9px rose "người ấy đang chờ bạn" dot (same as the rps medallion).
  final bool showDot;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: CustomPaint(
            size: const Size.square(26),
            painter: _GlyphPainter(mine, partner),
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

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.mine, this.partner);

  final Color mine;
  final Color partner;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.width / 2;
    final faint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(h, 0), Offset(h, size.height), faint);
    canvas.drawLine(Offset(0, h), Offset(size.width, h), faint);
    paintCaroStone(canvas, Offset(h / 2, h / 2), h, CaroSide.x, mine);
    paintCaroStone(canvas, Offset(h * 1.5, h * 1.5), h, CaroSide.o, partner);
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.mine != mine || oldDelegate.partner != partner;
}

/// 44px board thumbnail for the history rows (design §3.5): one dot per
/// stone in its player's colour, the winning run behind them. No text.
class CaroThumb extends StatelessWidget {
  const CaroThumb({
    super.key,
    required this.game,
    required this.colorX,
    required this.colorO,
  });

  final CaroGame game;
  final Color colorX;
  final Color colorO;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: CustomPaint(painter: _ThumbPainter(game, colorX, colorO)),
      ),
    );
  }
}

class _ThumbPainter extends CustomPainter {
  _ThumbPainter(this.game, this.colorX, this.colorO);

  final CaroGame game;
  final Color colorX;
  final Color colorO;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / CaroBoard.size;
    Offset c(int i) => Offset(
      (CaroBoard.colOf(i) + 0.5) * cell,
      (CaroBoard.rowOf(i) + 0.5) * cell,
    );
    final line = game.result?.line ?? const <int>[];
    if (line.length >= 2) {
      final side = game.board.pieceAt(line.first);
      canvas.drawLine(
        c(line.first),
        c(line.last),
        Paint()
          ..color = (side == CaroSide.o ? colorO : colorX).withValues(
            alpha: 0.35,
          )
          ..strokeWidth = cell * 1.1
          ..strokeCap = StrokeCap.round,
      );
    }
    for (var n = 0; n < game.cells.length; n++) {
      canvas.drawCircle(
        c(game.cells[n]),
        1.3,
        Paint()..color = n.isEven ? colorX : colorO,
      );
    }
  }

  @override
  bool shouldRepaint(_ThumbPainter oldDelegate) =>
      oldDelegate.game.id != game.id ||
      oldDelegate.game.cells.length != game.cells.length;
}

/// The 7-square rule picture "O X X X X X O" (design §3.2): the same row under
/// both rules, only the verdict next to it differs.
class CaroRuleExample extends StatelessWidget {
  const CaroRuleExample({
    super.key,
    required this.colorX,
    required this.colorO,
  });

  final Color colorX;
  final Color colorO;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: const Size(140, 20),
        painter: _RuleExamplePainter(colorX, colorO),
      ),
    );
  }
}

class _RuleExamplePainter extends CustomPainter {
  _RuleExamplePainter(this.colorX, this.colorO);

  final Color colorX;
  final Color colorO;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 20.0;
    final border = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 7; i++) {
      canvas.drawRect(Rect.fromLTWH(i * cell, 0, cell, cell), border);
      final o = i == 0 || i == 6;
      paintCaroStone(
        canvas,
        Offset(i * cell + cell / 2, cell / 2),
        cell,
        o ? CaroSide.o : CaroSide.x,
        o ? colorO : colorX,
      );
    }
  }

  @override
  bool shouldRepaint(_RuleExamplePainter oldDelegate) =>
      oldDelegate.colorX != colorX || oldDelegate.colorO != colorO;
}
