import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../models/couple.dart';
import '../../models/weather.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sleep_provider.dart';
import '../../providers/weather_provider.dart';
import '../../screens/care_message_screen.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/person_palette.dart';
import '../../utils/weather_logic.dart';
import '../content_card.dart';
import '../icon_badge.dart';
import '../today_constellation.dart' show MidnightBuilder;
import '../person_label.dart';
import '../shimmer_skeleton.dart';
import '../sleep/sleep_format.dart';
import 'weather_sheets.dart';

// ── Copy + icons shared by the card, the sheets and Settings ─────────────────

/// Analytics events of the feature (overview §8) — never a city, a
/// temperature or the note's text.
abstract final class WeatherEvents {
  static const String citySet = 'weather_city_set';
  static const String cardTap = 'weather_card_tap';
  static const String ctaTap = 'weather_cta_tap';
  static const String noticeToggle = 'weather_notif_toggle';
}

void logWeatherEvent(String name, Map<String, Object?> params) =>
    AnalyticsService.instance.logEvent(name, params: params);

/// `rain` / `hot` / `cold` — the analytics name of a nudge.
String weatherCtaCondition(WeatherCta cta) => switch (cta) {
  WeatherCta.umbrella => 'rain',
  WeatherCta.water => 'hot',
  WeatherCta.warm => 'cold',
};

String weatherSkyText(AppLocalizations l10n, WeatherSky sky) => switch (sky) {
  WeatherSky.clear => l10n.weatherSkyClear,
  WeatherSky.partlyCloudy => l10n.weatherSkyPartlyCloudy,
  WeatherSky.cloudy => l10n.weatherSkyCloudy,
  WeatherSky.fog => l10n.weatherSkyFog,
  WeatherSky.lightRain => l10n.weatherSkyLightRain,
  WeatherSky.rain => l10n.weatherSkyRain,
  WeatherSky.heavyRain => l10n.weatherSkyHeavyRain,
  WeatherSky.thunder => l10n.weatherSkyThunder,
  WeatherSky.snow => l10n.weatherSkySnow,
  WeatherSky.unknown => '',
};

/// The line under the temperature (§6.2); '' for an unknown MET code.
String weatherConditionText(AppLocalizations l10n, WeatherCondition c) =>
    switch (c.kind) {
      WeatherConditionKind.rainNow => l10n.weatherCondRainNow,
      WeatherConditionKind.rainThisMorning => l10n.weatherCondRainMorning,
      WeatherConditionKind.rainThisAfternoon => l10n.weatherCondRainAfternoon,
      WeatherConditionKind.rainTonight => l10n.weatherCondRainTonight,
      WeatherConditionKind.rainTomorrowMorning => l10n.weatherCondRainTomorrow,
      WeatherConditionKind.hot => l10n.weatherCondHot(c.max),
      WeatherConditionKind.cold => l10n.weatherCondCold(c.min),
      WeatherConditionKind.sky => weatherSkyText(l10n, c.sky),
    };

/// Design §7.
IconData weatherSkyIcon(WeatherSky sky, {bool night = false}) => switch (sky) {
  WeatherSky.clear => night ? IconsaxPlusLinear.moon : IconsaxPlusLinear.sun_1,
  WeatherSky.partlyCloudy =>
    night ? IconsaxPlusLinear.cloud : IconsaxPlusLinear.cloud_sunny,
  WeatherSky.fog => IconsaxPlusLinear.cloud_fog,
  WeatherSky.lightRain ||
  WeatherSky.rain ||
  WeatherSky.heavyRain => IconsaxPlusLinear.cloud_drizzle,
  WeatherSky.thunder => IconsaxPlusLinear.cloud_lightning,
  WeatherSky.snow => IconsaxPlusLinear.cloud_snow,
  WeatherSky.cloudy || WeatherSky.unknown => IconsaxPlusLinear.cloud,
};

String weatherCtaLabel(AppLocalizations l10n, WeatherCta cta, String name) =>
    switch (cta) {
      WeatherCta.umbrella => l10n.weatherCtaUmbrella(name),
      WeatherCta.water => l10n.weatherCtaWater(name),
      WeatherCta.warm => l10n.weatherCtaWarm(name),
    };

String weatherCtaA11y(AppLocalizations l10n, WeatherCta cta, String name) =>
    switch (cta) {
      WeatherCta.umbrella => l10n.weatherCtaA11yUmbrella(name),
      WeatherCta.water => l10n.weatherCtaA11yWater(name),
      WeatherCta.warm => l10n.weatherCtaA11yWarm(name),
    };

/// The care note the nudge prefills (§6.6) — [city] in the sender's language.
({String title, String body}) weatherCarePrefill(
  AppLocalizations l10n,
  WeatherCta cta, {
  required String city,
  required int min,
  required int max,
}) => switch (cta) {
  WeatherCta.umbrella => (
    title: l10n.weatherCareUmbrellaTitle,
    body: l10n.weatherCareUmbrellaBody(city),
  ),
  WeatherCta.water => (
    title: l10n.weatherCareWaterTitle,
    body: l10n.weatherCareWaterBody(city, max),
  ),
  WeatherCta.warm => (
    title: l10n.weatherCareWarmTitle,
    body: l10n.weatherCareWarmBody(city, min),
  ),
};

/// Nudge → the care screen, prefilled (D12, 2 taps to send). [entry] =
/// `card` · `sheet` · `notification`.
void openWeatherCare(
  BuildContext context, {
  required WeatherCta cta,
  required WeatherCity city,
  required int min,
  required int max,
  required String entry,
}) {
  final l10n = context.l10n;
  final note = weatherCarePrefill(
    l10n,
    cta,
    city: city.name(l10n.localeName),
    min: min,
    max: max,
  );
  logWeatherEvent(WeatherEvents.ctaTap, {
    'condition': weatherCtaCondition(cta),
    'entry': entry == 'notification' ? 'notification' : 'card',
  });
  openCareMessageScreen(
    context,
    initialTitle: note.title,
    initialBody: note.body,
    source: 'weather',
  );
}

/// "07:12" on the phone's clock.
String weatherHhmm(DateTime t) {
  final l = t.toLocal();
  return '${l.hour.toString().padLeft(2, '0')}:'
      '${l.minute.toString().padLeft(2, '0')}';
}

/// Names + colours of the two lanes, the way the "Đêm qua" card shows them
/// (one person = one colour on every Home card).
class WeatherPeople {
  const WeatherPeople({
    required this.me,
    required this.partner,
    required this.myColor,
    required this.partnerColor,
  });

  final String me;
  final String partner;
  final Color myColor;
  final Color partnerColor;

  static WeatherPeople of(BuildContext context, Couple couple) {
    final myUid = context.read<AuthProvider>().currentUser?.id;
    final colors = context.select<SleepProvider, (String, String)>(
      (s) => (s.myColorId, s.partnerColorId),
    );
    return WeatherPeople(
      me: context.l10n.sleepYou,
      partner: SleepFormat.partnerName(context, couple, myUid),
      myColor: PersonPalette.colorOf(colors.$1),
      partnerColor: PersonPalette.colorOf(colors.$2),
    );
  }
}

// ── The card ─────────────────────────────────────────────────────────────────

/// Home card "Thời tiết hai nơi" (feature weather, design §3.1 / §14b, Home C
/// §15): you left · your person right, the nudge under their lane; folds into
/// one row when there is nothing to mention; shown while waiting too (your
/// lane only). Home wraps it in a [KeyedSubtree] for `pendingHomeFocus`.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.couple});

  final Couple couple;

  @override
  Widget build(BuildContext context) {
    // Re-reads the condition at 0:00 without a network call (state 19).
    return MidnightBuilder(builder: (context) => _build(context));
  }

  Widget _build(BuildContext context) {
    final w = context.watch<WeatherProvider>();
    if (!w.cardVisible) {
      return const SizedBox.shrink();
    }
    final people = WeatherPeople.of(context, couple);
    final l10n = context.l10n;

    if (!w.choicesLoaded) {
      return _Shell(
        header: _header(l10n, stamp: null, loading: true),
        body: _loadingLanes(w, people, l10n),
      );
    }
    if (w.nothingPicked) {
      return _Shell(
        header: _header(l10n, stamp: null, chevron: false),
        body: _Invite(paired: w.isPaired, partnerName: people.partner),
      );
    }
    if (w.isLoadingFirst) {
      return _Shell(
        header: _header(l10n, stamp: null, loading: true),
        body: _loadingLanes(w, people, l10n),
      );
    }

    final places = [?w.myPlace, if (w.isPaired) ?w.partnerPlace];
    final worst = places.fold<WeatherFreshness>(
      WeatherFreshness.fresh,
      (a, p) => p.freshness.index > a.index ? p.freshness : a,
    );
    final error =
        worst == WeatherFreshness.none ||
        places.any((p) => p.condition == null);
    final stale = !error && worst == WeatherFreshness.stale;
    final fetched = [
      for (final p in places) ?w.forecastFor(p.cityId)?.fetchedAt,
    ]..sort();
    final oldest = fetched.isEmpty ? null : fetched.first;

    void retry() {
      HapticFeedback.selectionClick();
      w.refresh(force: true);
    }

    void openDetail() {
      HapticFeedback.selectionClick();
      logWeatherEvent(WeatherEvents.cardTap, {'state': _stateName(w, error)});
      showWeatherDetailSheet(context, couple: couple);
    }

    if (!error && !stale && w.compact) {
      return _Shell(
        onTap: openDetail,
        body: _CompactRow(weather: w, people: people),
      );
    }

    final String? stamp = error
        ? null
        : stale
        ? l10n.weatherStaleHeader
        : oldest == null
        ? null
        : l10n.weatherUpdatedAt(weatherHhmm(oldest));

    final Widget? footer;
    if (error) {
      footer = _StatusRow(text: l10n.weatherLoadFailed, onRetry: retry);
    } else if (stale) {
      footer = _StatusRow(
        text: oldest == null ? '' : l10n.weatherStaleAt(weatherHhmm(oldest)),
        icon: IconsaxPlusLinear.clock,
        onRetry: retry,
      );
    } else {
      footer = _sharedRow(context, w, people);
    }

    final reduce = AppMotion.reduceMotion(context);
    return _Shell(
      onTap: error ? retry : openDetail,
      header: _header(l10n, stamp: stamp, chevron: !error),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Lanes(weather: w, people: people, muted: stale, labelsOnly: error),
          AnimatedSize(
            duration: reduce ? Duration.zero : AppMotion.fast,
            curve: AppMotion.curve,
            alignment: Alignment.topCenter,
            child: footer == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 1,
                          color: AppColors.textSecondary.withValues(
                            alpha: 0.10,
                          ),
                        ),
                        const SizedBox(height: 12),
                        footer,
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  static String _stateName(WeatherProvider w, bool error) {
    if (error) return 'error';
    final mine = w.myCity != null;
    final theirs = w.isPaired && w.partnerCity != null;
    if (mine && theirs) return 'both';
    if (mine) return 'mine_only';
    if (theirs) return 'partner_only';
    return 'empty';
  }

  Widget _header(
    AppLocalizations l10n, {
    required String? stamp,
    bool chevron = true,
    bool loading = false,
  }) {
    return Row(
      children: [
        const IconBadge(IconsaxPlusLinear.cloud_sunny),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.weatherCardTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (loading) ...[
                const SizedBox(height: 4),
                const ShimmerSkeleton(width: 84, height: 14, borderRadius: 7),
              ] else if (stamp != null) ...[
                const SizedBox(height: 2),
                Text(
                  stamp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (chevron && !loading)
          const Icon(
            IconsaxPlusLinear.arrow_right_3,
            size: 18,
            color: AppColors.textTertiary,
          ),
      ],
    );
  }

  Widget _loadingLanes(
    WeatherProvider w,
    WeatherPeople people,
    AppLocalizations l10n,
  ) {
    Widget lane(String name, Color color) => Semantics(
      label: l10n.weatherCardTitle,
      // ponytail: no dedicated "loading" string; the title is read.
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PersonLabel(name: name, color: color),
            const SizedBox(height: 6),
            const Row(
              children: [
                ShimmerSkeleton(width: 58, height: 33, borderRadius: 10),
                SizedBox(width: 8),
                ShimmerSkeleton(width: 24, height: 24, borderRadius: 12),
              ],
            ),
            const SizedBox(height: 6),
            const ShimmerSkeleton(width: 96, height: 16, borderRadius: 8),
          ],
        ),
      ),
    );
    final me = lane(people.me, people.myColor);
    if (!w.isPaired) {
      return me;
    }
    return _TwoLanes(
      left: me,
      right: lane(people.partner, people.partnerColor),
    );
  }

  /// Design §9.7: nudge (right, under their lane) > ≥ 5° gap > nothing.
  Widget? _sharedRow(
    BuildContext context,
    WeatherProvider w,
    WeatherPeople people,
  ) {
    final l10n = context.l10n;
    switch (w.sharedRow) {
      case WeatherSharedRow.none:
        return null;
      case WeatherSharedRow.gap:
        final gap = weatherTempGap(
          w.myPlace!.condition!.temp,
          w.partnerPlace!.condition!.temp,
        )!;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              gap < 0
                  ? l10n.weatherColder(people.partner, -gap)
                  : l10n.weatherWarmer(people.partner, gap),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      case WeatherSharedRow.cta:
        final c = w.partnerPlace!.condition!;
        return Align(
          alignment: AlignmentDirectional.centerEnd,
          child: WeatherNudgeButton(
            cta: c.cta!,
            partnerName: people.partner,
            onPressed: () => openWeatherCare(
              context,
              cta: c.cta!,
              city: w.partnerCity!,
              min: c.min,
              max: c.max,
              entry: 'card',
            ),
          ),
        );
    }
  }
}

/// The navy "Nhắc Thảo mang ô" pill (card + detail sheet): one line, cut
/// with "…" when the name is long; the screen reader hears it whole.
class WeatherNudgeButton extends StatelessWidget {
  const WeatherNudgeButton({
    super.key,
    required this.cta,
    required this.partnerName,
    required this.onPressed,
  });

  final WeatherCta cta;
  final String partnerName;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Semantics(
      button: true,
      label: weatherCtaA11y(l10n, cta, partnerName),
      hint: l10n.weatherCtaHint,
      container: true,
      excludeSemantics: true,
      child: SizedBox(
        height: 44,
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.selectionClick();
            onPressed();
          },
          icon: const Icon(IconsaxPlusLinear.message_favorite, size: 18),
          label: Text(
            weatherCtaLabel(l10n, cta, partnerName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
        ),
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({this.header, required this.body, this.onTap});

  final Widget? header;
  final Widget body;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) ...[header!, const SizedBox(height: 14)],
          body,
        ],
      ),
    );
    return ContentCard(
      padding: EdgeInsets.zero,
      child: onTap == null
          ? content
          : Semantics(
              button: true,
              hint: context.l10n.weatherCardHint,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  splashColor: AppColors.accentRose.withValues(alpha: 0.08),
                  highlightColor: AppColors.accentRose.withValues(alpha: 0.04),
                  onTap: onTap,
                  child: content,
                ),
              ),
            ),
    );
  }
}

/// Invite (§14b): Đêm qua's setup shape — line + "Chọn thành phố" + "Ẩn".
class _Invite extends StatelessWidget {
  const _Invite({required this.paired, required this.partnerName});

  final bool paired;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          paired
              ? l10n.weatherSetupBody(partnerName)
              : l10n.weatherSetupBodySolo,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Flexible(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    showCityPickerSheet(
                      context,
                      forPartner: false,
                      chain: paired,
                      partnerName: partnerName,
                      entry: 'card',
                    );
                  },
                  icon: const Icon(IconsaxPlusLinear.location, size: 18),
                  label: Text(
                    l10n.weatherSetupCta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Semantics(
              button: true,
              label: l10n.weatherHideA11y,
              container: true,
              excludeSemantics: true,
              child: TextButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  context.read<WeatherProvider>().hideCard();
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: AppColors.textSecondary,
                ),
                child: Text(
                  l10n.weatherHide,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Home C §15: one 76 px row when there is nothing to mention.
class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.weather, required this.people});

  final WeatherProvider weather;
  final WeatherPeople people;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = l10n.localeName;
    final mine = weather.myPlace!.condition!;
    final theirs = weather.isPaired ? weather.partnerPlace?.condition : null;
    final myCity = weather.myCity!;
    final partnerCity = weather.isPaired ? weather.partnerCity : null;
    final sameCity = partnerCity != null && partnerCity.id == myCity.id;
    final myText = weatherConditionText(l10n, mine);
    final showCond =
        theirs == null ||
        sameCity ||
        myText == weatherConditionText(l10n, theirs);

    Widget chip(Color color, String city, int temp) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$city '),
                TextSpan(
                  text: '$temp°',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final label = [
      l10n.weatherCardTitle,
      '${people.me}: ${myCity.name(lang)} ${l10n.weatherDegrees(mine.temp)}',
      if (theirs != null && partnerCity != null && !sameCity)
        '${people.partner}: ${partnerCity.name(lang)} ${l10n.weatherDegrees(theirs.temp)}',
      if (myText.isNotEmpty) myText,
    ].join('. ');

    return Semantics(
      label: label,
      container: true,
      excludeSemantics: true,
      child: Row(
        children: [
          const IconBadge(IconsaxPlusLinear.cloud_sunny),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weatherCardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 2,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      chip(people.myColor, myCity.shortName(lang), mine.temp),
                      if (theirs != null && partnerCity != null && !sameCity)
                        chip(
                          people.partnerColor,
                          partnerCity.shortName(lang),
                          theirs.temp,
                        ),
                      if (showCond && myText.isNotEmpty) Text(myText),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            IconsaxPlusLinear.arrow_right_3,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}

class _TwoLanes extends StatelessWidget {
  const _TwoLanes({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 14),
              child: left,
            ),
          ),
          Container(
            width: 1,
            color: AppColors.textSecondary.withValues(alpha: 0.10),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 14),
              child: right,
            ),
          ),
        ],
      ),
    );
  }
}

/// You left · your person right; one lane while waiting or in the same city.
class _Lanes extends StatelessWidget {
  const _Lanes({
    required this.weather,
    required this.people,
    required this.muted,
    required this.labelsOnly,
  });

  final WeatherProvider weather;
  final WeatherPeople people;
  final bool muted;
  final bool labelsOnly;

  @override
  Widget build(BuildContext context) {
    final w = weather;
    final my = w.myCity;
    final theirs = w.isPaired ? w.partnerCity : null;
    if (my != null && theirs != null && my.id == theirs.id) {
      return _Lane(
        label: _SameCityLabel(people: people, city: my),
        a11yName: context.l10n.weatherSameCity(
          my.name(context.l10n.localeName),
        ),
        city: null,
        place: w.myPlace,
        muted: muted,
        labelsOnly: labelsOnly,
      );
    }
    final mine = my == null
        ? _UnsetLane(
            question: context.l10n.weatherWhereAmI,
            button: context.l10n.weatherChoose,
            color: people.myColor,
            onTap: () => showCityPickerSheet(
              context,
              forPartner: false,
              partnerName: people.partner,
              entry: 'card',
            ),
          )
        : _Lane(
            label: PersonLabel(name: people.me, color: people.myColor),
            a11yName: people.me,
            city: my,
            place: w.myPlace,
            muted: muted,
            labelsOnly: labelsOnly,
          );
    if (!w.isPaired) {
      return mine;
    }
    final partner = theirs == null
        ? _UnsetLane(
            question: context.l10n.weatherWhereIsPartner(people.partner),
            button: context.l10n.weatherChooseForPartner,
            color: people.partnerColor,
            onTap: () => showCityPickerSheet(
              context,
              forPartner: true,
              partnerName: people.partner,
              entry: 'card',
            ),
          )
        : _Lane(
            label: PersonLabel(
              name: people.partner,
              color: people.partnerColor,
            ),
            a11yName: people.partner,
            city: theirs,
            place: w.partnerPlace,
            muted: muted,
            labelsOnly: labelsOnly,
          );
    return _TwoLanes(left: mine, right: partner);
  }
}

class _SameCityLabel extends StatelessWidget {
  const _SameCityLabel({required this.people, required this.city});

  final WeatherPeople people;
  final WeatherCity city;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        SizedBox(
          width: 14,
          height: 8,
          child: Stack(
            children: [
              _dot(people.myColor),
              Positioned(
                left: 5,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: people.partnerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            l10n.weatherSameCity(city.shortName(l10n.localeName)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _dot(Color c) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

class _Lane extends StatelessWidget {
  const _Lane({
    required this.label,
    required this.a11yName,
    required this.city,
    required this.place,
    required this.muted,
    required this.labelsOnly,
  });

  final Widget label;
  final String a11yName;

  /// Null in the same-city lane (the label already names it).
  final WeatherCity? city;
  final WeatherPlace? place;
  final bool muted;
  final bool labelsOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = l10n.localeName;
    final c = place?.condition;
    final cityName = city?.shortName(lang);
    if (labelsOnly || c == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          if (cityName != null) ...[
            const SizedBox(height: 6),
            Text(
              cityName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      );
    }
    final ink = muted ? AppColors.textSecondary : AppColors.textPrimary;
    final cond = weatherConditionText(l10n, c);
    final line = [?cityName, if (cond.isNotEmpty) cond].join(' · ');
    final reduce = AppMotion.reduceMotion(context);
    return Semantics(
      label: [
        a11yName,
        if (city != null) city!.name(lang),
        l10n.weatherDegrees(c.temp),
        if (cond.isNotEmpty) cond,
      ].join(', '),
      container: true,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          label,
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: reduce ? Duration.zero : AppMotion.fast,
            switchInCurve: AppMotion.curve,
            child: Column(
              key: ValueKey('${c.temp}|${c.kind}|${c.sky}|$muted'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${c.temp}°',
                          maxLines: 1,
                          style: TextStyle(
                            color: ink,
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      weatherSkyIcon(c.sky, night: c.night),
                      size: 24,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

/// "Bạn đang ở đâu? [Chọn]" / "Thảo đang ở đâu? [Chọn giúp]".
class _UnsetLane extends StatelessWidget {
  const _UnsetLane({
    required this.question,
    required this.button,
    required this.color,
    required this.onTap,
  });

  final String question;
  final String button;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                question,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            icon: const Icon(IconsaxPlusLinear.location, size: 18),
            label: Text(
              button,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: AppColors.textPrimary,
              shape: const StadiumBorder(),
              side: BorderSide(
                color: AppColors.textPrimary.withValues(alpha: 0.18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Chưa tải được thời tiết · Thử lại" / "⏱ Số liệu lúc 21:40 · Thử lại".
class WeatherStatusRow extends StatelessWidget {
  const WeatherStatusRow({
    super.key,
    required this.text,
    required this.onRetry,
    this.icon,
  });

  final String text;
  final IconData? icon;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Semantics(
            liveRegion: true,
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(IconsaxPlusLinear.refresh, size: 18),
          label: Text(
            context.l10n.weatherRetry,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

typedef _StatusRow = WeatherStatusRow;
