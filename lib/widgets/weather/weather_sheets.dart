import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/weather_cities.dart';
import '../../l10n/l10n.dart';
import '../../models/couple.dart';
import '../../models/weather.dart';
import '../../providers/couple_provider.dart';
import '../../providers/weather_provider.dart';
import '../../services/reminder_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/weather_logic.dart';
import '../content_card.dart';
import '../icon_badge.dart';
import '../person_label.dart';
import '../section_header.dart';
import 'weather_card.dart';

// ── MET Norway credit (D2, design §4.6) ──────────────────────────────────────

/// "Dữ liệu thời tiết: MET Norway" — required by MET's licence (CC BY 4.0).
class MetCredit extends StatelessWidget {
  const MetCredit({super.key});

  static final Uri licence = Uri.parse('https://api.met.no/doc/License');

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      link: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => launchUrl(licence, mode: LaunchMode.externalApplication),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: l10n.weatherSourcePrefix),
                  const TextSpan(
                    text: 'MET Norway',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget _handle() => Center(
  child: Container(
    width: 36,
    height: 4,
    decoration: BoxDecoration(
      color: const Color(0xFFE2DDE6),
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

Divider _rule() => Divider(
  height: 1,
  thickness: 1,
  color: AppColors.textSecondary.withValues(alpha: 0.10),
);

// ── Feature tour ("Có gì mới", build 33) ────────────────────────────────────

/// The tour row opens the feature: the city picker when nothing is picked
/// yet (first-time chain when paired), else the detail sheet.
void openWeatherFromTour(BuildContext context) {
  final couple = context.read<CoupleProvider>().couple;
  final w = context.read<WeatherProvider>();
  if (couple == null || !w.isUsingFirebase) {
    return;
  }
  if (w.nothingPicked) {
    showCityPickerSheet(
      context,
      forPartner: false,
      chain: w.isPaired,
      partnerName: WeatherPeople.of(context, couple).partner,
      entry: 'card',
    );
  } else {
    showWeatherDetailSheet(context, couple: couple);
  }
}

// ── Detail sheet (design §3.3 / §4.2) ────────────────────────────────────────

Future<void> showWeatherDetailSheet(
  BuildContext context, {
  required Couple couple,
}) {
  final people = WeatherPeople.of(context, couple);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * 0.9,
    ),
    builder: (_) => _DetailSheet(people: people),
  );
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.people});

  final WeatherPeople people;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final w = context.watch<WeatherProvider>();
    final my = w.myCity;
    final theirs = w.isPaired ? w.partnerCity : null;
    final same = my != null && theirs != null && my.id == theirs.id;

    final places = [?w.myPlace, if (w.isPaired) ?w.partnerPlace];
    final fetched = [
      for (final p in places) ?w.forecastFor(p.cityId)?.fetchedAt,
    ]..sort();
    final stale = places.any((p) => p.freshness != WeatherFreshness.fresh);
    final stamp = fetched.isEmpty
        ? null
        : stale
        ? l10n.weatherStaleAt(weatherHhmm(fetched.first))
        : l10n.weatherUpdatedAt(weatherHhmm(fetched.first));

    // One shared scale for both places (the signature element).
    final conds = [
      for (final p in places)
        if (p.condition != null) p.condition!,
    ];
    final scaleMin = conds.isEmpty
        ? 0
        : conds.map((c) => c.min).reduce((a, b) => a < b ? a : b);
    final scaleMax = conds.isEmpty
        ? 0
        : conds.map((c) => c.max).reduce((a, b) => a > b ? a : b);

    final blocks = <Widget>[
      _PlaceBlock(
        who: _Who.me,
        people: people,
        city: my,
        same: same,
        scaleMin: scaleMin,
        scaleMax: scaleMax,
      ),
      if (w.isPaired && !same)
        _PlaceBlock(
          who: _Who.partner,
          people: people,
          city: theirs,
          same: false,
          scaleMin: scaleMin,
          scaleMax: scaleMax,
        ),
    ];

    final bottom = MediaQuery.paddingOf(context).bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 32 + bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _handle(),
          const SizedBox(height: 16),
          Text(
            l10n.weatherCardTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (stamp != null) ...[
            const SizedBox(height: 2),
            Text(
              stamp,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) _rule(),
            blocks[i],
          ],
          const SizedBox(height: 8),
          const MetCredit(),
        ],
      ),
    );
  }
}

enum _Who { me, partner }

class _PlaceBlock extends StatelessWidget {
  const _PlaceBlock({
    required this.who,
    required this.people,
    required this.city,
    required this.same,
    required this.scaleMin,
    required this.scaleMax,
  });

  final _Who who;
  final WeatherPeople people;
  final WeatherCity? city;
  final bool same;
  final int scaleMin;
  final int scaleMax;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = l10n.localeName;
    final w = context.watch<WeatherProvider>();
    final mine = who == _Who.me;
    final name = mine ? people.me : people.partner;
    final color = mine ? people.myColor : people.partnerColor;
    final c = city;

    void pick() => showCityPickerSheet(
      context,
      forPartner: !mine,
      partnerName: people.partner,
      entry: 'sheet',
    );

    if (c == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: PersonLabel(
                name: mine
                    ? l10n.weatherWhereAmI
                    : l10n.weatherWhereIsPartner(name),
                color: color,
              ),
            ),
            _ActionButton(
              text: mine ? l10n.weatherChoose : l10n.weatherChooseForPartner,
              onTap: pick,
            ),
          ],
        ),
      );
    }

    final place = w.placeFor(c);
    final cond = place?.condition;
    final now = DateTime.now();
    final cityOffset = WeatherProvider.cityUtcOffset(c, now);
    final otherClock = cityOffset != now.timeZoneOffset;

    final Widget trailing;
    if (mine) {
      trailing = _ActionButton(text: l10n.weatherChangeCity, onTap: pick);
    } else if (w.canPickForPartner) {
      trailing = _ActionButton(text: l10n.weatherChangeForPartner, onTap: pick);
    } else {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            IconsaxPlusLinear.tick_circle,
            size: 14,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            l10n.weatherPartnerSelfSet(name),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final muted = place?.freshness != WeatherFreshness.fresh;
    final ink = muted ? AppColors.textSecondary : AppColors.textPrimary;
    final region = c.region(lang);
    final condText = cond == null ? '' : weatherConditionText(l10n, cond);
    final cta = !mine && place != null && place.usable ? cond?.cta : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: same
                    ? Text(
                        l10n.weatherSameCity(c.name(lang)),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : PersonLabel(name: name, color: color),
              ),
              if (otherClock)
                Text(
                  ' · ${l10n.weatherTheirTimeNow(_wallHhmm(now.toUtc().add(cityOffset)))}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: c.name(lang),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (region.isNotEmpty)
                        TextSpan(
                          text: ' · $region',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              trailing,
            ],
          ),
          if (cond == null || place!.freshness == WeatherFreshness.none) ...[
            const SizedBox(height: 8),
            WeatherStatusRow(
              text: l10n.weatherLoadFailed,
              onRetry: () => w.refresh(force: true),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${cond.temp}°',
                  style: TextStyle(
                    color: ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  weatherSkyIcon(cond.sky, night: cond.night),
                  size: 24,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    condText,
                    style: TextStyle(
                      color: ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TempScale(
              condition: cond,
              color: color,
              scaleMin: scaleMin,
              scaleMax: scaleMax,
            ),
            if (cta != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: WeatherNudgeButton(
                  cta: cta,
                  partnerName: people.partner,
                  onPressed: () => openWeatherCare(
                    context,
                    cta: cta,
                    city: c,
                    min: cond.min,
                    max: cond.max,
                    entry: 'sheet',
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _HourSlots(hours: w.forecastFor(c.id)?.hours ?? const [], city: c),
          ],
        ],
      ),
    );
  }
}

/// "10:10" of a UTC instant already shifted to the city's wall clock.
String _wallHhmm(DateTime wall) =>
    '${wall.hour.toString().padLeft(2, '0')}:'
    '${wall.minute.toString().padLeft(2, '0')}';

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      icon: const Icon(IconsaxPlusLinear.location, size: 18),
      label: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: TextButton.styleFrom(
        minimumSize: const Size(44, 44),
        foregroundColor: AppColors.textPrimary,
      ),
    );
  }
}

/// "Từ giờ tới khuya 25° – 33°" + the low–high bar on the scale both places
/// share, knob at the current temperature.
class _TempScale extends StatelessWidget {
  const _TempScale({
    required this.condition,
    required this.color,
    required this.scaleMin,
    required this.scaleMax,
  });

  final WeatherCondition condition;
  final Color color;
  final int scaleMin;
  final int scaleMax;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final c = condition;
    final span = (scaleMax - scaleMin).clamp(1, 1000);
    double at(int t) => ((t - scaleMin) / span).clamp(0.0, 1.0);
    const muted = TextStyle(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );
    return Semantics(
      label: l10n.weatherScaleA11y(c.min, c.max, c.temp),
      container: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.weatherRestOfDay(c.min, c.max), style: muted),
          const SizedBox(height: 8),
          SizedBox(
            height: 14,
            child: LayoutBuilder(
              builder: (context, box) {
                final wdt = box.maxWidth;
                final left = at(c.min) * wdt;
                final right = at(c.max) * wdt;
                final knob = at(c.temp) * wdt;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 4,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: left,
                      width: (right - left).clamp(6, wdt),
                      top: 4,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    Positioned(
                      left: (knob - 7).clamp(0, wdt - 14),
                      top: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: color, width: 2),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('$scaleMin°', style: muted.copyWith(fontSize: 12)),
              const Spacer(),
              Text('$scaleMax°', style: muted.copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Next 5 three-hour marks on the city's own clock.
class _HourSlots extends StatelessWidget {
  const _HourSlots({required this.hours, required this.city});

  final List<WeatherHour> hours;
  final WeatherCity city;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now().toUtc();
    final slots = <(String, WeatherHour)>[];
    for (final h in hours) {
      if (!h.t.isAfter(now)) continue;
      final wall = h.t.add(WeatherProvider.cityUtcOffset(city, h.t));
      if (wall.hour % 3 != 0) continue;
      slots.add(('${wall.hour.toString().padLeft(2, '0')}:00', h));
      if (slots.length == 5) break;
    }
    if (slots.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        for (final (label, h) in slots)
          Expanded(
            child: Semantics(
              label: weatherHourIsRainy(h)
                  ? l10n.weatherSlotRainA11y(label, h.temp.round())
                  : l10n.weatherSlotA11y(label, h.temp.round()),
              container: true,
              excludeSemantics: true,
              child: Column(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(
                    weatherSkyIcon(
                      weatherSkyOf(h.symbol),
                      night: weatherSymbolIsNight(h.symbol),
                    ),
                    size: 22,
                    color: weatherHourIsRainy(h)
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${h.temp.round()}°',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── City picker (design §3.4 / §4.3, §14b picker-chain) ──────────────────────

/// Picks my city ([forPartner] false) or my partner's (D6). [chain]: the
/// first-time flow from the invite card — after my city, the same sheet asks
/// "Còn Thảo đang ở đâu?" with "Để sau" (3 taps for both). [entry] =
/// `card` · `settings` · `sheet` (analytics).
Future<void> showCityPickerSheet(
  BuildContext context, {
  required bool forPartner,
  required String partnerName,
  required String entry,
  bool chain = false,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scroll) => CityPicker(
        scroll: scroll,
        forPartner: forPartner,
        chain: chain,
        partnerName: partnerName,
        entry: entry,
        messenger: messenger,
      ),
    ),
  );
}

/// The picker body (public for widget tests).
class CityPicker extends StatefulWidget {
  const CityPicker({
    super.key,
    this.scroll,
    required this.forPartner,
    required this.partnerName,
    required this.entry,
    this.chain = false,
    this.messenger,
  });

  final ScrollController? scroll;
  final bool forPartner;
  final bool chain;
  final String partnerName;
  final String entry;
  final ScaffoldMessengerState? messenger;

  @override
  State<CityPicker> createState() => _CityPickerState();
}

sealed class _Item {
  const _Item();
}

class _Group extends _Item {
  const _Group(this.title);
  final String title;
}

class _Row extends _Item {
  const _Row(this.hit);
  final WeatherCityHit hit;
}

class _Empty extends _Item {
  const _Empty();
}

class _Credit extends _Item {
  const _Credit();
}

class _CityPickerState extends State<CityPicker> {
  final TextEditingController _query = TextEditingController();
  late bool _forPartner = widget.forPartner;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  List<_Item> _items(AppLocalizations l10n, String? currentId) {
    final hits = searchWeatherCities(_query.text);
    if (hits.isEmpty) {
      return const [_Empty(), _Credit()];
    }
    final showCurrent = _query.text.trim().isEmpty && currentId != null;
    final vn = <_Item>[];
    final intl = <_Item>[];
    _Row? current;
    for (final h in hits) {
      if (showCurrent && h.city.id == currentId) {
        current = _Row(h);
        continue;
      }
      (h.city.isVietnam ? vn : intl).add(_Row(h));
    }
    return [
      if (current != null) ...[_Group(l10n.weatherGroupCurrent), current],
      if (vn.isNotEmpty) ...[_Group(l10n.weatherGroupVn), ...vn],
      if (intl.isNotEmpty) ...[_Group(l10n.weatherGroupIntl), ...intl],
      const _Credit(),
    ];
  }

  void _pick(WeatherCity city) {
    HapticFeedback.selectionClick();
    final w = context.read<WeatherProvider>();
    final l10n = context.l10n;
    final forPartner = _forPartner;
    final write = forPartner ? w.setPartnerCity(city.id) : w.setMyCity(city.id);
    final messenger = widget.messenger ?? ScaffoldMessenger.maybeOf(context);
    final name = widget.partnerName;
    write.then((ok) {
      if (ok) {
        logWeatherEvent(WeatherEvents.citySet, {
          'who': forPartner ? 'partner' : 'self',
          'region': city.isVietnam ? 'vn' : 'intl',
          'entry': widget.entry,
        });
        return;
      }
      messenger
        ?..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              forPartner
                  ? l10n.weatherPartnerJustSet(name)
                  : l10n.weatherSaveFailed,
            ),
          ),
        );
    });
    if (widget.chain && !forPartner && w.canPickForPartner) {
      setState(() {
        _forPartner = true;
        _query.clear();
      });
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = l10n.localeName;
    final w = context.watch<WeatherProvider>();
    final currentId = (_forPartner ? w.partnerChoice : w.myChoice)?.cityId;
    final items = _items(l10n, currentId);
    final chainStep2 = widget.chain && _forPartner;
    final title = !_forPartner
        ? l10n.weatherWhereAmI
        : chainStep2
        ? l10n.weatherWhereIsPartnerNext(widget.partnerName)
        : l10n.weatherWhereIsPartner(widget.partnerName);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _handle(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (chainStep2)
                      TextButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(44, 44),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: Text(
                          l10n.weatherLater,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _forPartner
                      ? l10n.weatherPickerSubPartner(widget.partnerName)
                      : l10n.weatherPickerSubSelf,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Semantics(
                  label: l10n.weatherSearchLabel,
                  textField: true,
                  child: TextField(
                    controller: _query,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: l10n.weatherSearchHint,
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        IconsaxPlusLinear.search_normal_1,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: l10n.weatherClearSearch,
                              constraints: const BoxConstraints(
                                minWidth: 44,
                                minHeight: 44,
                              ),
                              onPressed: _query.clear,
                              icon: const Icon(
                                IconsaxPlusLinear.close_circle,
                                size: 20,
                                color: AppColors.textSecondary,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: widget.scroll,
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              itemCount: items.length,
              itemBuilder: (context, i) => switch (items[i]) {
                _Group(:final title) => Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 4),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Row(:final hit) => _CityRow(
                  hit: hit,
                  lang: lang,
                  selected: hit.city.id == currentId,
                  divider: i + 1 < items.length && items[i + 1] is _Row,
                  onTap: () => _pick(hit.city),
                ),
                _Empty() => Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    l10n.weatherNoMatch,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _Credit() => const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: MetCredit(),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.hit,
    required this.lang,
    required this.selected,
    required this.divider,
    required this.onTap,
  });

  final WeatherCityHit hit;
  final String lang;
  final bool selected;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = hit.city;
    final region = c.region(lang);
    final via = hit.via;
    return Semantics(
      selected: selected,
      button: true,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            splashColor: AppColors.accentRose.withValues(alpha: 0.08),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 52),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: c.name(lang),
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                                if (region.isNotEmpty)
                                  TextSpan(
                                    text: ' · $region',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (via != null)
                            Text(
                              context.l10n.weatherOldProvince(via),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selected)
                      const Icon(
                        IconsaxPlusBold.tick_circle,
                        size: 20,
                        color: AppColors.textPrimary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (divider) _rule(),
        ],
      ),
    );
  }
}

// ── Settings section (design §3.5 / §4.5, Lead: no "Giờ báo" row) ────────────

/// "Thời tiết hai nơi" in Cài đặt: your city · your person's city · the 07:30
/// notice switch + preview + MET credit.
class WeatherSettingsSection extends StatelessWidget {
  const WeatherSettingsSection({super.key, required this.couple});

  final Couple couple;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = l10n.localeName;
    final w = context.watch<WeatherProvider>();
    if (!w.isUsingFirebase) {
      return const SizedBox.shrink();
    }
    final people = WeatherPeople.of(context, couple);
    final paired = w.isPaired;
    final my = w.myCity;
    final theirs = w.partnerCity;

    String partnerSub() {
      if (theirs == null) return l10n.weatherNotSet;
      final by = w.partnerChoice!.setBySelf
          ? l10n.weatherPartnerSelfSet(people.partner)
          : l10n.weatherSetByMe;
      return '${theirs.name(lang)} · $by';
    }

    Future<void> toggle(bool value) async {
      HapticFeedback.selectionClick();
      final messenger = ScaffoldMessenger.of(context);
      if (value && !await ReminderService.instance.requestPermissions()) {
        messenger
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(content: Text(l10n.remindersPermissionDeniedMsg)),
          );
        return;
      }
      logWeatherEvent(WeatherEvents.noticeToggle, {'enabled': value});
      await w.setNoticeEnabled(value);
    }

    final noticeOn = paired && w.noticeEnabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: l10n.weatherSettingsSection),
        const SizedBox(height: 12),
        ContentCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            children: [
              _SettingsRow(
                icon: IconsaxPlusLinear.location,
                title: l10n.weatherSettingsMine,
                subtitle: my?.name(lang) ?? l10n.weatherNotSet,
                onTap: () => showCityPickerSheet(
                  context,
                  forPartner: false,
                  partnerName: people.partner,
                  entry: 'settings',
                ),
              ),
              if (paired) ...[
                const _SettingsDivider(),
                _SettingsRow(
                  icon: IconsaxPlusLinear.location,
                  title: l10n.weatherSettingsPartner(people.partner),
                  subtitle: partnerSub(),
                  onTap: w.canPickForPartner
                      ? () => showCityPickerSheet(
                          context,
                          forPartner: true,
                          partnerName: people.partner,
                          entry: 'settings',
                        )
                      : null,
                ),
              ],
              const _SettingsDivider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    const IconBadge(IconsaxPlusLinear.notification_bing),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _RowText(
                        title: l10n.weatherNotifToggle,
                        subtitle: paired
                            ? l10n.weatherNotifToggleSub(
                                weatherMorningTimeText(context),
                                people.partner,
                              )
                            : l10n.weatherNotifNeedsCouple,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch.adaptive(
                      value: noticeOn,
                      activeThumbColor: AppColors.accentRose,
                      onChanged: paired ? toggle : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (noticeOn) ...[
          const SizedBox(height: 12),
          Text(
            l10n.weatherNotifPreviewCaption(people.partner),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _NoticePreview(
            title: l10n.weatherMorningRainTitle(
              (theirs ?? kWeatherCities[1]).name(lang),
            ),
            body: l10n.weatherMorningRainBody(people.partner),
          ),
        ],
        const SizedBox(height: 4),
        const MetCredit(),
      ],
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 58),
    child: Divider(
      height: 1,
      color: AppColors.textTertiary.withValues(alpha: 0.18),
    ),
  );
}

class _RowText extends StatelessWidget {
  const _RowText({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// Same shape as Settings' `_navRow` (that one is private to the screen).
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          IconBadge(icon),
          const SizedBox(width: 14),
          Expanded(
            child: _RowText(title: title, subtitle: subtitle),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(
              IconsaxPlusLinear.arrow_right_3,
              size: 24,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.accentRose.withValues(alpha: 0.08),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap!();
        },
        child: row,
      ),
    );
  }
}

/// The lock-screen look of a rainy-morning notice, in the app's font.
class _NoticePreview extends StatelessWidget {
  const _NoticePreview({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.sunset1,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              IconsaxPlusBold.heart,
              size: 20,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      weatherMorningTimeText(context),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
