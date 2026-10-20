import '../models/arrival.dart';

/// Sender-side half of the edge filter (arrival D6). The CF does the other
/// half (30' cooldown per place, 6 pushes/day, events older than 30').

/// A re-entry this soon after leaving the same place is a trip to the bin or
/// the lobby, not a homecoming: sent as `bounce` (card only, no push).
const Duration kArrivalBounceWindow = Duration(minutes: 10);

/// Last known in/out state of one place on this phone (Hive).
class ArrivalEdgeState {
  const ArrivalEdgeState({this.inside, this.exitAt});

  /// Null = unknown (new place, fresh install): the first event always counts.
  final bool? inside;
  final DateTime? exitAt;

  Map<String, dynamic> toJson() => {
    'inside': ?inside,
    'exitAt': ?exitAt?.millisecondsSinceEpoch,
  };

  factory ArrivalEdgeState.fromJson(Object? raw) {
    if (raw is! Map) return const ArrivalEdgeState();
    final exit = raw['exitAt'];
    final inside = raw['inside'];
    return ArrivalEdgeState(
      inside: inside is bool ? inside : null,
      exitAt: exit is int ? DateTime.fromMillisecondsSinceEpoch(exit) : null,
    );
  }
}

/// [send] false = drop (same state twice — iOS fires the first event twice
/// after a reboot). [bounce] marks the event for the CF. [next] is stored.
typedef ArrivalEdgeDecision = ({bool send, bool bounce, ArrivalEdgeState next});

ArrivalEdgeDecision filterArrivalEdge(
  ArrivalEdgeState state,
  ArrivalEventType type,
  DateTime at,
) {
  if (type == ArrivalEventType.exit) {
    if (state.inside == false) {
      return (send: false, bounce: false, next: state);
    }
    return (
      send: true,
      bounce: false,
      next: ArrivalEdgeState(inside: false, exitAt: at),
    );
  }
  if (state.inside == true) {
    return (send: false, bounce: false, next: state);
  }
  final exitAt = state.exitAt;
  final sinceExit = exitAt == null ? null : at.difference(exitAt);
  final bounce =
      sinceExit != null &&
      !sinceExit.isNegative &&
      sinceExit < kArrivalBounceWindow;
  return (
    send: true,
    bounce: bounce,
    next: ArrivalEdgeState(inside: true, exitAt: exitAt),
  );
}
