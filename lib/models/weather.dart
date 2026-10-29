/// Feature: weather ("Thời tiết hai nơi") — each member picks one city from a
/// bundled list (no location permission); the Home card shows the weather at
/// both places. Choices live at `couples/{coupleId}/weather/{uid}` (cityId +
/// who picked it); forecasts come from the `getCityWeather` callable (MET
/// Norway, cached per city server-side) and are kept in Hive for offline use.
library;

/// One city of the bundled list (`lib/data/weather_cities.dart`). Names are
/// shown as-is per app language; [regionVi]/[regionEn] are empty for the 6
/// centrally-run cities (the UI then shows just the name).
class WeatherCity {
  const WeatherCity({
    required this.id,
    required this.nameVi,
    required this.nameEn,
    this.shortEn = '',
    this.regionVi = '',
    this.regionEn = '',
    required this.lat,
    required this.lon,
    required this.tz,
    this.aliases = const <String>[],
  });

  /// Stable slug (`vn-da-lat`, `kr-seoul`) — stored in Firestore, never renamed.
  final String id;
  final String nameVi;
  final String nameEn;

  /// Shorter English name for the narrow Home lane ("HCMC"); '' = use [nameEn].
  final String shortEn;
  final String regionVi;
  final String regionEn;

  /// City centre, 2 decimals (MET allows at most 4).
  final double lat;
  final double lon;

  /// IANA zone, used to read the forecast hours on the city's own clock.
  final String tz;

  /// Former province names, unaccented / English spellings — search only.
  final List<String> aliases;

  bool get isVietnam => id.startsWith('vn-');

  String name(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;

  /// Name for tight spots (the Home lane): the short English form when set.
  String shortName(String languageCode) =>
      languageCode != 'vi' && shortEn.isNotEmpty ? shortEn : name(languageCode);

  String region(String languageCode) =>
      languageCode == 'vi' ? regionVi : regionEn;
}

/// A member's choice: `weather/{uid}` = { cityId, setBy, updatedAt }.
/// [setBy] != [uid] means the partner picked it for them (D6) — still
/// changeable by the partner until the owner picks one themselves.
class WeatherChoice {
  const WeatherChoice({
    required this.uid,
    required this.cityId,
    required this.setBy,
  });

  final String uid;
  final String cityId;
  final String setBy;

  bool get setBySelf => setBy == uid;

  static WeatherChoice? fromDoc(String uid, Map<String, dynamic>? data) {
    final cityId = data?['cityId'];
    if (cityId is! String || cityId.isEmpty) {
      return null;
    }
    final setBy = data?['setBy'];
    return WeatherChoice(
      uid: uid,
      cityId: cityId,
      setBy: setBy is String ? setBy : '',
    );
  }
}

/// One forecast hour as the callable returns it (D8: raw numbers, UTC).
/// [rain] = mm in the hour starting at [t]; [symbol] = MET `symbol_code` with
/// its `_day` / `_night` suffix.
class WeatherHour {
  const WeatherHour({
    required this.t,
    required this.temp,
    required this.symbol,
    required this.rain,
  });

  final DateTime t;
  final double temp;
  final String symbol;
  final double rain;

  static WeatherHour? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final t = raw['t'];
    final temp = raw['temp'];
    if (t is! num || temp is! num) {
      return null;
    }
    final symbol = raw['symbol'];
    final rain = raw['rain'];
    return WeatherHour(
      t: DateTime.fromMillisecondsSinceEpoch(t.toInt(), isUtc: true),
      temp: temp.toDouble(),
      symbol: symbol is String ? symbol : '',
      rain: rain is num ? rain.toDouble() : 0,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    't': t.millisecondsSinceEpoch,
    'temp': temp,
    'symbol': symbol,
    'rain': rain,
  };
}

/// One city's forecast: [fetchedAt] = when the server got it from MET (drives
/// the "Cập nhật 07:12" line and the 3 freshness levels, D16). [checkedAt] =
/// when THIS phone last asked the callable (the 30-minute client throttle).
class CityForecast {
  const CityForecast({
    required this.fetchedAt,
    required this.checkedAt,
    required this.hours,
  });

  final DateTime fetchedAt;
  final DateTime checkedAt;
  final List<WeatherHour> hours;

  static CityForecast? fromJson(Object? raw, {DateTime? checkedAt}) {
    if (raw is! Map) {
      return null;
    }
    final fetchedAt = raw['fetchedAt'];
    final hoursRaw = raw['hours'];
    if (fetchedAt is! num || hoursRaw is! List) {
      return null;
    }
    final checked = raw['checkedAt'];
    final hours = <WeatherHour>[
      for (final h in hoursRaw) ?WeatherHour.fromJson(h),
    ]..sort((a, b) => a.t.compareTo(b.t));
    return CityForecast(
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        fetchedAt.toInt(),
        isUtc: true,
      ),
      checkedAt:
          checkedAt ??
          (checked is num
              ? DateTime.fromMillisecondsSinceEpoch(
                  checked.toInt(),
                  isUtc: true,
                )
              : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)),
      hours: hours,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'fetchedAt': fetchedAt.millisecondsSinceEpoch,
    'checkedAt': checkedAt.millisecondsSinceEpoch,
    'hours': [for (final h in hours) h.toJson()],
  };
}
