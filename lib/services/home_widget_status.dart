import '../l10n/app_localizations.dart';
// ── caro-game (đợt 2) ──
import '../models/caro_game.dart';
// ── arrival (đợt 2) ──
import '../models/arrival.dart';
import '../models/decision.dart';
import '../models/photo.dart';
import '../utils/decision_suggester.dart' show decisionDisplayName;
import '../widgets/mood_card.dart' show moodLabel;
import '../widgets/today_constellation.dart';
import 'daily_question_service.dart';

/// A decision-wheel result for today (feature decision-wheel). Passed in by
/// the caller once a `DecisionProvider` exists; null = nothing decided.
class WidgetDecision {
  const WidgetDecision({
    required this.kind,
    required this.result,
    this.question = '',
    this.at,
  });

  /// `eat` · `go` · `custom`.
  final String kind;
  final String result;

  /// The custom question ("Ai rửa bát?"), only for [kind] `custom`.
  final String question;
  final DateTime? at;
}

/// The "hôm nay" line on the home-screen widget (feature widget-today), as the
/// map `updateStatus` sends over `dear_embeiu/widget` (D6). Pure: both the app
/// (from live providers, [build]) and the background push handler ([fromPush])
/// use it, so the two paths print the same words (D5). Native only shows
/// `statusText` (medium) / `statusTextShort` (small) when `todayDate` is the
/// day it draws (D4.1).
abstract final class HomeWidgetStatus {
  static const String questionPartner = 'question_partner';
  static const String questionBoth = 'question_both';
  static const String questionMine = 'question_mine';
  static const String mood = 'mood';
  static const String message = 'message';
  static const String photo = 'photo';
  static const String decisionEat = 'decision_eat';
  static const String decisionGo = 'decision_go';
  static const String decisionCustom = 'decision_custom';
  // ── caro-game (đợt 2) ──
  static const String caroTurn = 'caro_turn';
  // ── arrival (đợt 2) ── the partner got Home / reached a named place.
  static const String arrivalHome = 'arrival_home';
  static const String arrivalPlace = 'arrival_place';

  /// `statusTarget` → Home tab index (mirrors HomeScreen's IndexedStack).
  static const Map<String, int> targetTabs = {
    'home': 0,
    'chat': 1,
    'gallery': 2,
  };

  /// Valid `statusFocus` values (HomeScreen._applyPendingFocus).
  static const Set<String> focuses = {
    'daily_question',
    'mood',
    'decision',
    // ── caro-game (đợt 2) ──
    'caro',
    // ── arrival (đợt 2) ──
    'arrival',
  };

  /// Every kind, for whitelisting what comes back from a widget tap.
  static const Set<String> kinds = {
    questionPartner,
    questionBoth,
    questionMine,
    mood,
    message,
    photo,
    decisionEat,
    decisionGo,
    decisionCustom,
    // ── caro-game (đợt 2) ──
    caroTurn,
    // ── arrival (đợt 2) ──
    arrivalHome,
    arrivalPlace,
  };

  /// No line today: the widget looks exactly like 1.9.1 (D12).
  static Map<String, String> none(DateTime now) => {
    'todayDate': DailyQuestionService.dateKey(now),
    'statusKind': '',
    'statusText': '',
    'statusTextShort': '',
    'statusAt': '0',
    'statusTarget': '',
    'statusFocus': '',
  };

  /// From the app's live state (D5a). Newest thing wins (D3); about the
  /// partner only what already happened, about me only "đang chờ mình" (D4).
  /// [active] = a couple with both members. [questionReady] = the question
  /// provider is on today and has loaded (otherwise "waiting for me" would be
  /// a guess).
  static Map<String, String> build({
    required TodayConstellation today,
    required AppLocalizations l10n,
    required DateTime now,
    required bool active,
    required String partnerName,
    required bool questionReady,
    DateTime? partnerPhotoAt,
    WidgetDecision? decision,
    // ── caro-game (đợt 2) ──
    DateTime? caroTurnAt,
    // ── arrival (đợt 2) ── `ArrivalProvider.partnerLast`.
    ArrivalEvent? partnerArrival,
  }) {
    if (!active) {
      return none(now);
    }
    final name = partnerName.trim().isEmpty
        ? l10n.reactionPartnerFallback
        : partnerName.trim();
    final candidates = <Map<String, String>>[];
    void add(Map<String, String>? s) {
      if (s != null) {
        candidates.add(s);
      }
    }

    final mineQ = today.star(true, CareTask.question);
    final theirQ = today.star(false, CareTask.question);
    if (theirQ.lit && mineQ.lit) {
      final a = theirQ.at ?? now;
      final b = mineQ.at ?? now;
      add(_status(l10n, questionBoth, a.isAfter(b) ? a : b, now));
    } else if (theirQ.lit) {
      add(_status(l10n, questionPartner, theirQ.at ?? now, now, name: name));
    } else if (!mineQ.lit && questionReady) {
      // Oldest possible time: any real event of today replaces it.
      add(
        _status(
          l10n,
          questionMine,
          DateTime(now.year, now.month, now.day),
          now,
        ),
      );
    }
    final theirMood = today.star(false, CareTask.mood);
    if (theirMood.lit && theirMood.moodKey != null) {
      add(
        _status(
          l10n,
          mood,
          theirMood.at ?? now,
          now,
          name: name,
          mood: theirMood.moodKey!,
        ),
      );
    }
    final theirMsg = today.star(false, CareTask.message);
    if (theirMsg.lit) {
      add(_status(l10n, message, theirMsg.at ?? now, now, name: name));
    }
    if (partnerPhotoAt != null && _sameDay(partnerPhotoAt, now)) {
      add(_status(l10n, photo, partnerPhotoAt, now, name: name));
    }
    if (decision != null) {
      final at = decision.at ?? now;
      if (_sameDay(at, now)) {
        add(
          _decision(
            l10n,
            decision.kind,
            decision.result,
            decision.question,
            at,
            now,
          ),
        );
      }
    }
    // ── caro-game (đợt 2) ──
    if (caroTurnAt != null && _sameDay(caroTurnAt, now)) {
      add(_status(l10n, caroTurn, caroTurnAt, now, name: name));
    }
    // ── arrival (đợt 2) ── only an arrival of today, never a departure (D4).
    final arrival = partnerArrival;
    if (arrival != null &&
        arrival.type == ArrivalEventType.enter &&
        _sameDay(arrival.at.toLocal(), now)) {
      add(
        _status(
          l10n,
          arrival.isHome ? arrivalHome : arrivalPlace,
          arrival.at.toLocal(),
          now,
          name: name,
          result: arrival.name ?? '',
        ),
      );
    }
    if (candidates.isEmpty) {
      return none(now);
    }
    // Strictly newer replaces: on a tie the earlier entry (question first) stays.
    var best = candidates.first;
    for (final c in candidates.skip(1)) {
      if (int.parse(c['statusAt']!) > int.parse(best['statusAt']!)) {
        best = c;
      }
    }
    return best;
  }

  // ── caro-game (đợt 2) ──
  /// When the partner's move made it my turn in [open] (overview §7.1,
  /// `statusAt = lastMoveAt`); null when it isn't my turn.
  static DateTime? caroTurnAt(CaroGame? open, String? myUid) {
    if (open == null || myUid == null || !open.isMyTurn(myUid)) {
      return null;
    }
    final by = open.lastMoveBy;
    if (by != null && by == myUid) {
      return null;
    }
    return open.lastMoveAt;
  }

  /// The partner's newest photo of today ([photos] newest-first or not).
  static DateTime? latestPartnerPhotoAt(
    List<Photo> photos,
    String? myUid,
    DateTime now,
  ) {
    DateTime? best;
    for (final p in photos) {
      final author = p.authorUserId;
      if (author == null || author.isEmpty || author == myUid) {
        continue;
      }
      final at = p.uploadDate.toLocal();
      if (_sameDay(at, now) && (best == null || at.isAfter(best))) {
        best = at;
      }
    }
    return best;
  }

  /// Language of a push for the background handler: `data.lang` (written per
  /// device by the CF), else the phone's locale ([platformLocale], e.g.
  /// `Platform.localeName` = "vi_VN").
  static String pushLang(Map<String, dynamic> data, String platformLocale) {
    final lang = '${data['lang'] ?? ''}'.trim().toLowerCase();
    if (lang == 'vi' || lang == 'en') {
      return lang;
    }
    return platformLocale.toLowerCase().startsWith('vi') ? 'vi' : 'en';
  }

  /// From a push handled in the background (D5b, D9: only the push's own
  /// data, no reads). Null = not a widget event, or not about today. Carries
  /// `onlyIfNewer` so native keeps a newer line of the same day (D3), except
  /// `partner_left`, which clears an older line ([none] + `clearIfOlder`).
  /// [sentAt] = `RemoteMessage.sentTime` (often null on iOS); the CF's
  /// `data.sentAt` (epoch ms) wins over it. A push with no `date` and no send
  /// time can't be proven to be today's → ignored (B2).
  static Map<String, String>? fromPush(
    Map<String, dynamic> data, {
    required AppLocalizations l10n,
    required DateTime now,
    DateTime? sentAt,
  }) {
    String v(String key) => '${data[key] ?? ''}'.trim();
    if (v('type') == 'partner_left') {
      // The partner left (CF notifyPartnerLeft, wakeClients): drop the line.
      // Not `state=empty`, which would also wipe the day count (B5). With a
      // send time (CF `sentAt`, else FCM sentTime) native clears only a line
      // OLDER than the leave and blocks later pushes from before it
      // (`clearIfOlder`, WT-R2-1) — a late push must not wipe the new
      // couple's line, nor the old partner's chat reappear. No time at all →
      // clear unconditionally, as before.
      final leftMs =
          int.tryParse(v('sentAt')) ?? sentAt?.millisecondsSinceEpoch ?? 0;
      if (leftMs <= 0) return none(now);
      return {...none(now), 'statusAt': '$leftMs', 'clearIfOlder': '1'};
    }
    final sentMs = int.tryParse(v('sentAt'));
    final sent =
        (sentMs != null && sentMs > 0
                ? DateTime.fromMillisecondsSinceEpoch(sentMs)
                : sentAt)
            ?.toLocal();
    final date = v('date');
    if (date.isNotEmpty) {
      if (date != DailyQuestionService.dateKey(now)) {
        return null; // a push about another day (queued while offline, D9)
      }
    } else if (sent == null || !_sameDay(sent, now)) {
      // ── caro-game (đợt 2) ──
      // Caro pushes carry no date on purpose (the CF's time zone isn't the
      // user's): a wake push is handled as it arrives, so "now" is today.
      final caro = v('type') == 'caro_turn' || v('type') == 'caro_invite';
      if (!caro || (sent != null && !_sameDay(sent, now))) {
        return null;
      }
    }
    final at = sent ?? now;
    final name = v('actorName').isEmpty
        ? l10n.reactionPartnerFallback
        : v('actorName');
    Map<String, String>? s;
    switch (v('type')) {
      case 'daily_question':
        s = v('bothAnswered').toLowerCase() == 'true'
            ? _status(l10n, questionBoth, at, now)
            : _status(l10n, questionPartner, at, now, name: name);
      case 'partner_mood':
        if (moodLabel(l10n, v('mood')).isNotEmpty) {
          s = _status(l10n, mood, at, now, name: name, mood: v('mood'));
        }
      case 'chat_message':
        s = _status(l10n, message, at, now, name: name);
      case 'photo_posted':
        s = _status(l10n, photo, at, now, name: name);
      case 'decision':
        // A bank pick reads in THIS phone's language (B3), not the spinner's.
        final kind = decisionKindFromString(v('kind'));
        final result = kind == null
            ? v('result')
            : decisionDisplayName(
                kind,
                v('result'),
                v('resultId'),
                english: l10n.localeName.startsWith('en'),
              );
        s = _decision(l10n, v('kind'), result, v('question'), at, now);
      // ── caro-game (đợt 2) ──
      case 'caro_turn':
      case 'caro_invite':
        s = _status(l10n, caroTurn, at, now, name: name);
      // ── arrival (đợt 2) ── CF notifyArrival: `place` slot, `placeName`.
      case 'arrival':
        final home = v('place') == 'home';
        if (home || v('placeName').isNotEmpty) {
          s = _status(
            l10n,
            home ? arrivalHome : arrivalPlace,
            at,
            now,
            name: name,
            result: v('placeName'),
          );
        }
    }
    return s == null ? null : {...s, 'onlyIfNewer': '1'};
  }

  static Map<String, String>? _decision(
    AppLocalizations l10n,
    String kind,
    String result,
    String question,
    DateTime at,
    DateTime now,
  ) {
    // Bank activities are stored as English verbs ("play pool") when the
    // chooser used English; lead with a capital like the card does.
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    result = '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
    switch (kind) {
      case 'eat':
        return _status(l10n, decisionEat, at, now, result: result.trim());
      case 'go':
        return _status(l10n, decisionGo, at, now, result: result.trim());
      case 'custom':
        // No question to show → read like a plan ("Hôm nay: …").
        return question.trim().isEmpty
            ? _status(l10n, decisionGo, at, now, result: result.trim())
            : _status(
                l10n,
                decisionCustom,
                at,
                now,
                result: result.trim(),
                question: question.trim(),
              );
    }
    return null;
  }

  static Map<String, String> _status(
    AppLocalizations l10n,
    String kind,
    DateTime at,
    DateTime now, {
    String name = '',
    String mood = '',
    String result = '',
    String question = '',
  }) {
    final moodText = mood.isEmpty ? '' : moodLabel(l10n, mood).toLowerCase();
    final (
      String text,
      String short,
      String target,
      String focus,
    ) = switch (kind) {
      questionPartner => (
        l10n.widgetStatusQuestionPartner(name),
        l10n.widgetStatusShortQuestionPartner(name),
        'home',
        'daily_question',
      ),
      questionBoth => (
        l10n.widgetStatusQuestionBoth,
        l10n.widgetStatusShortQuestionBoth,
        'home',
        'daily_question',
      ),
      questionMine => (
        l10n.widgetStatusQuestionMine,
        l10n.widgetStatusShortQuestionMine,
        'home',
        'daily_question',
      ),
      HomeWidgetStatus.mood => (
        l10n.widgetStatusMood(name, moodText),
        l10n.widgetStatusShortMood(name, moodText),
        'home',
        'mood',
      ),
      message => (
        l10n.widgetStatusMessage(name),
        l10n.widgetStatusShortMessage(name),
        'chat',
        '',
      ),
      photo => (
        l10n.widgetStatusPhoto(name),
        l10n.widgetStatusShortPhoto(name),
        'gallery',
        '',
      ),
      decisionEat => (
        l10n.widgetStatusDecisionEat(result),
        l10n.widgetStatusShortDecisionEat(result),
        'home',
        'decision',
      ),
      decisionGo => (
        l10n.widgetStatusDecisionGo(result),
        l10n.widgetStatusShortDecisionGo(result),
        'home',
        'decision',
      ),
      // ── caro-game (đợt 2) ──
      caroTurn => (
        l10n.caroWidgetTurn(name),
        l10n.caroWidgetTurnShort,
        'home',
        'caro',
      ),
      // ── arrival (đợt 2) ── [result] carries the place name.
      arrivalHome => (
        l10n.arrivalWidgetHome(name),
        l10n.arrivalWidgetHomeShort(name),
        'home',
        'arrival',
      ),
      arrivalPlace => (
        l10n.arrivalWidgetPlace(name, result),
        l10n.arrivalWidgetPlaceShort(name, result),
        'home',
        'arrival',
      ),
      _ => (
        l10n.widgetStatusDecisionCustom(question, result),
        l10n.widgetStatusShortDecisionCustom(result),
        'home',
        'decision',
      ),
    };
    return {
      'todayDate': DailyQuestionService.dateKey(now),
      'statusKind': kind,
      'statusText': text,
      'statusTextShort': short,
      'statusAt': '${at.millisecondsSinceEpoch}',
      'statusTarget': target,
      'statusFocus': focus,
    };
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
