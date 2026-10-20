// Feature arrival ("Về đến nhà chưa?", đợt 2 — overview D1, D3, D19–D23).
//
// Two worlds, never mixed:
//  • [ArrivalPlace] — my places. Address + coordinates live ONLY on this phone
//    (Hive `arrival_nobackup`, D2). Never sent to Firestore.
//  • [ArrivalEvent] — the one latest event per member on
//    `couples/{c}/arrival/{uid}.last` (D3). It carries a snapshot of the
//    place's name + icon (D23), never an address or a coordinate.

/// Slot ids, stable so the CF can rate-limit per place. `home` always exists.
const List<String> kArrivalSlots = ['home', 'p1', 'p2', 'p3', 'p4'];
const String kArrivalHome = 'home';

/// Custom places on top of Home (D19).
const int kArrivalMaxCustom = 4;

/// Place name limit (D19). Counted in UTF-16 units = Dart `String.length` =
/// what rules `string.size()` counts (measured on the emulator, decision-wheel
/// DW-R2-1) — not runes as the spec draft said.
const int kArrivalNameMax = 24;

/// Geofence radius by how the place was set (D1). Tune within 100–400 m after
/// the stage-2 spike.
const int kArrivalRadiusAddress = 250;
const int kArrivalRadiusCurrent = 150;

/// The 7 icon keys (D19). Stored as a key, never an emoji.
enum ArrivalIcon { work, school, family, gym, cafe, shop, pin }

ArrivalIcon? arrivalIconFromKey(Object? key) {
  for (final icon in ArrivalIcon.values) {
    if (icon.name == key) return icon;
  }
  return null;
}

/// Trimmed name if valid (1–24, one line), else null.
String? normalizeArrivalName(String raw) {
  final name = raw.trim();
  if (name.isEmpty || name.length > kArrivalNameMax) return null;
  if (name.contains('\n') || name.contains('\r')) return null;
  return name;
}

enum ArrivalLocationSource { address, current }

/// Where a place is — this phone only (D2).
class ArrivalLocation {
  const ArrivalLocation({
    required this.lat,
    required this.lng,
    required this.source,
    required this.savedAt,
    int? radius,
    this.address,
  }) : radius =
           radius ??
           (source == ArrivalLocationSource.current
               ? kArrivalRadiusCurrent
               : kArrivalRadiusAddress);

  final double lat;
  final double lng;
  final ArrivalLocationSource source;
  final DateTime savedAt;

  /// Metres.
  final int radius;

  /// Full address the OS geocoder returned (null for "current location").
  final String? address;

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'radius': radius,
    'source': source.name,
    'savedAt': savedAt.millisecondsSinceEpoch,
    'address': ?address,
  };

  static ArrivalLocation? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final lat = raw['lat'];
    final lng = raw['lng'];
    final saved = raw['savedAt'];
    if (lat is! num || lng is! num || saved is! int) return null;
    final source = raw['source'] == ArrivalLocationSource.current.name
        ? ArrivalLocationSource.current
        : ArrivalLocationSource.address;
    final radius = raw['radius'];
    return ArrivalLocation(
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      source: source,
      savedAt: DateTime.fromMillisecondsSinceEpoch(saved),
      radius: radius is int ? radius : null,
      address: raw['address'] as String?,
    );
  }
}

/// One of my places. Home: no name/icon (the app shows "Nhà"/"Home"), can't be
/// deleted or renamed, may have no location yet. Custom: name required, icon
/// defaults to [ArrivalIcon.pin], location optional ("chỉ bấm tay").
class ArrivalPlace {
  const ArrivalPlace({required this.slot, this.name, this.icon, this.location});

  const ArrivalPlace.home({this.location})
    : slot = kArrivalHome,
      name = null,
      icon = null;

  final String slot;
  final String? name;
  final ArrivalIcon? icon;
  final ArrivalLocation? location;

  bool get isHome => slot == kArrivalHome;

  ArrivalPlace withLocation(ArrivalLocation? location) =>
      ArrivalPlace(slot: slot, name: name, icon: icon, location: location);

  Map<String, dynamic> toJson() => {
    'name': ?name,
    'icon': ?icon?.name,
    'location': ?location?.toJson(),
  };

  /// Null when the stored entry is unusable (a custom place without a valid
  /// name, an unknown slot).
  static ArrivalPlace? fromJson(String slot, Object? raw) {
    if (!kArrivalSlots.contains(slot) || raw is! Map) return null;
    final location = ArrivalLocation.fromJson(raw['location']);
    if (slot == kArrivalHome) return ArrivalPlace.home(location: location);
    final name = normalizeArrivalName('${raw['name'] ?? ''}');
    if (name == null) return null;
    return ArrivalPlace(
      slot: slot,
      name: name,
      icon: arrivalIconFromKey(raw['icon']) ?? ArrivalIcon.pin,
      location: location,
    );
  }
}

enum ArrivalEventType { enter, exit }

enum ArrivalEventSource { auto, manual }

/// `couples/{c}/arrival/{uid}.last` — the latest event (D3, D23).
class ArrivalEvent {
  const ArrivalEvent({
    required this.place,
    required this.type,
    required this.at,
    required this.source,
    this.name,
    this.icon,
    this.battery,
    this.bounce = false,
  });

  /// Snapshot of [p] at the time of the event (D23): later renames don't
  /// change what was sent.
  factory ArrivalEvent.at(
    ArrivalPlace p, {
    required ArrivalEventType type,
    required DateTime at,
    required ArrivalEventSource source,
    int? battery,
    bool bounce = false,
  }) => ArrivalEvent(
    place: p.slot,
    name: p.isHome ? null : p.name,
    icon: p.isHome ? null : (p.icon ?? ArrivalIcon.pin),
    type: type,
    at: at,
    source: source,
    battery: battery,
    bounce: bounce,
  );

  final String place;
  final String? name;
  final ArrivalIcon? icon;
  final ArrivalEventType type;
  final DateTime at;
  final ArrivalEventSource source;

  /// 0..100, null when the battery couldn't be read.
  final int? battery;

  /// Re-entry within 10' of leaving the same place (D6): the CF won't push.
  final bool bounce;

  bool get isHome => place == kArrivalHome;

  /// Firestore map; [timestamp] converts [at] (the service passes
  /// `Timestamp.fromDate`, keeping this file free of cloud_firestore).
  Map<String, dynamic> toMap(Object Function(DateTime) timestamp) => {
    'place': place,
    if (!isHome) 'name': ?name,
    if (!isHome) 'icon': ?icon?.name,
    'type': type.name,
    'at': timestamp(at),
    if (battery != null) 'battery': battery!.clamp(0, 100),
    'source': source.name,
    if (bounce) 'bounce': true,
  };

  /// Lenient read of someone else's event; null when unusable.
  static ArrivalEvent? fromMap(
    Object? raw,
    DateTime? Function(Object?) toDate,
  ) {
    if (raw is! Map) return null;
    final place = raw['place'];
    final at = toDate(raw['at']);
    if (place is! String || !kArrivalSlots.contains(place) || at == null) {
      return null;
    }
    final battery = raw['battery'];
    return ArrivalEvent(
      place: place,
      name: place == kArrivalHome ? null : raw['name'] as String?,
      icon: place == kArrivalHome ? null : arrivalIconFromKey(raw['icon']),
      type: raw['type'] == 'exit'
          ? ArrivalEventType.exit
          : ArrivalEventType.enter,
      at: at,
      source: raw['source'] == 'auto'
          ? ArrivalEventSource.auto
          : ArrivalEventSource.manual,
      battery: battery is int ? battery : null,
      bounce: raw['bounce'] == true,
    );
  }
}

/// A member's doc `couples/{c}/arrival/{uid}` as the app sees it.
class ArrivalShare {
  const ArrivalShare({
    required this.share,
    this.auto = false,
    this.last,
    this.pending = false,
  });

  final bool share;

  /// Their phone sends on its own (card says "tự báo" vs "chỉ bấm tay").
  final bool auto;

  /// Null while sharing is off (rules forbid `last` then, D11).
  final ArrivalEvent? last;

  /// The snapshot still holds a local write the server hasn't acked (only
  /// meaningful on my own doc): "Sẽ báo khi có mạng" stays while true.
  final bool pending;
}
