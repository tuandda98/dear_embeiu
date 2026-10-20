// Address search helpers for feature arrival (D20, spike §6.8). Pure Dart.
//
// The OS geocoders get Vietnamese addresses wrong mostly because of the ward /
// district part (old names after the 2025 merge send "Phương Mai, Đống Đa, Hà
// Nội" to Ninh Bình). Typed in full: 60% within 250 m; "number + street +
// province" only: 75% (MKLocalSearch). So the app sends the short form and
// throws away results in another province than the one typed.

/// What the app actually sends for one typed address.
class ArrivalPlaceQuery {
  const ArrivalPlaceQuery({
    required this.text,
    this.province,
    this.alley = false,
  });

  /// Shortened query ('' = nothing worth sending).
  final String text;

  /// Province group typed at the end (key of [kArrivalProvinces]), or null.
  final String? province;

  /// The house number was an alley one ("45/12"): only the alley mouth was
  /// sent, so every result is approximate.
  final bool alley;
}

/// The 34 provinces since 1/7/2025, each with the old names merged into it and
/// common short forms (folded: lower case, no diacritics). Old names stay
/// because people still type them and geocoders still know some.
const Map<String, List<String>> kArrivalProvinces = {
  'ha noi': ['ha noi', 'hanoi', 'hn', 'ha tay'],
  'hue': ['hue', 'thua thien hue', 'tt hue'],
  'lai chau': ['lai chau'],
  'dien bien': ['dien bien'],
  'son la': ['son la'],
  'lang son': ['lang son'],
  'quang ninh': ['quang ninh'],
  'thanh hoa': ['thanh hoa'],
  'nghe an': ['nghe an'],
  'ha tinh': ['ha tinh'],
  'cao bang': ['cao bang'],
  'tuyen quang': ['tuyen quang', 'ha giang'],
  'lao cai': ['lao cai', 'yen bai'],
  'thai nguyen': ['thai nguyen', 'bac kan', 'bac can'],
  'phu tho': ['phu tho', 'vinh phuc', 'hoa binh'],
  'bac ninh': ['bac ninh', 'bac giang'],
  'hung yen': ['hung yen', 'thai binh'],
  'hai phong': ['hai phong', 'haiphong', 'hai duong'],
  'ninh binh': ['ninh binh', 'ha nam', 'nam dinh'],
  'quang tri': ['quang tri', 'quang binh'],
  'da nang': ['da nang', 'danang', 'quang nam'],
  'quang ngai': ['quang ngai', 'kon tum'],
  'gia lai': ['gia lai', 'binh dinh'],
  'khanh hoa': ['khanh hoa', 'ninh thuan'],
  'lam dong': ['lam dong', 'dak nong', 'binh thuan'],
  'dak lak': ['dak lak', 'daklak', 'phu yen'],
  'ho chi minh': [
    'ho chi minh',
    'hcm',
    'tphcm',
    'hcmc',
    'hcm city',
    'ho chi minh city',
    'sai gon',
    'saigon',
    'binh duong',
    'ba ria vung tau',
    'ba ria',
    'vung tau',
  ],
  'dong nai': ['dong nai', 'binh phuoc'],
  'tay ninh': ['tay ninh', 'long an'],
  'can tho': ['can tho', 'soc trang', 'hau giang'],
  'vinh long': ['vinh long', 'ben tre', 'tra vinh'],
  'dong thap': ['dong thap', 'tien giang'],
  'ca mau': ['ca mau', 'bac lieu'],
  'an giang': ['an giang', 'kien giang'],
};

const _from = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
const _to = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

/// Lower case, no Vietnamese diacritics, punctuation → spaces, single spaces.
String foldVi(String s) {
  final lower = s.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    final i = _from.indexOf(ch);
    out.write(i >= 0 ? _to[i] : ch);
  }
  return out
      .toString()
      // Combining marks (NFD input from some keyboards).
      .replaceAll(RegExp('[̀-ͯ]'), '')
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();
}

final _adminPrefix = RegExp(
  r'^(phuong|quan|xa|huyen|thi xa|thi tran|khu pho|to dan pho|ap)( |$)',
);
final _adminShort = RegExp(
  r'^(p|q|tx|tt|h|x)\.|^(p|q)\s*\d+$',
  caseSensitive: false,
);
final _provincePrefix = RegExp(r'^(thanh pho|tinh|tp) ?');
final _country = RegExp(r'^(viet nam|vietnam|vn)$');
// "Số 45/12 …", "Hẻm 45/12 …", "45/12/3 …", "201B …".
final _alley = RegExp(
  r'^(?:(?:số|so|hẻm|hem|ngõ|ngo|ngách|ngach|kiệt|kiet)\s+)?(\d+[A-Za-z]?)\s*/\s*\d+[A-Za-z]?(?:\s*/\s*\d+[A-Za-z]?)*\s+(.+)$',
  caseSensitive: false,
  unicode: true,
);
final _houseNumber = RegExp(
  r'^(?:(?:số|so)\s+)?\d',
  caseSensitive: false,
  unicode: true,
);

/// Province group of one comma part ("TP.HCM", "Thành phố Huế", "Hà Nội"),
/// or null.
String? arrivalProvinceOf(String part) {
  final folded = foldVi(part).replaceFirst(_provincePrefix, '').trim();
  if (folded.isEmpty) return null;
  for (final e in kArrivalProvinces.entries) {
    if (e.value.contains(folded)) return e.key;
  }
  return null;
}

/// "45/12 Lê Văn Sỹ, Phường 13, Quận 3, TP.HCM" → "45 Lê Văn Sỹ, TP.HCM"
/// (alley). Keeps the house number + street and the province; drops ward,
/// district, commune parts. Without a province at the end only the parts
/// marked as ward/district go (an unmarked "Thanh Xuân" may be the only hint).
ArrivalPlaceQuery shortenArrivalPlaceQuery(String raw) {
  final parts = raw
      .replaceAll(RegExp(r'[\r\n]+'), ', ')
      .split(',')
      .map((p) => p.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((p) => p.isNotEmpty)
      .toList();
  while (parts.length > 1 && _country.hasMatch(foldVi(parts.last))) {
    parts.removeLast();
  }
  if (parts.isEmpty) return const ArrivalPlaceQuery(text: '');

  String? province;
  String? provinceText;
  if (parts.length > 1) {
    province = arrivalProvinceOf(parts.last);
    if (province != null) provinceText = parts.removeLast();
  }

  final body = [
    for (final p in parts)
      if (!_adminPrefix.hasMatch(foldVi(p)) && !_adminShort.hasMatch(p)) p,
  ];

  var alley = false;
  final List<String> kept;
  final numbered = body.where(_houseNumber.hasMatch).firstOrNull;
  if (numbered != null && (province != null || body.length == 1)) {
    kept = [numbered];
  } else {
    kept = body;
  }
  for (var i = 0; i < kept.length; i++) {
    final m = _alley.firstMatch(kept[i]);
    if (m != null) {
      alley = true;
      kept[i] = '${m.group(1)} ${m.group(2)}';
    }
  }
  return ArrivalPlaceQuery(
    text: [...kept, ?provinceText].join(', '),
    province: province,
    alley: alley,
  );
}

bool _containsName(String foldedAddress, String name) =>
    RegExp('(^| )${RegExp.escape(name)}( |\$)').hasMatch(foldedAddress);

/// A result is kept when it names the typed province (or one merged into it),
/// or names no province at all. One naming another province only is dropped
/// ("78 Giải Phóng, Hà Nội" → a "Giải Phóng" street in Ninh Bình). A street
/// called after a province ("124 Hải Phòng, … Đà Nẵng") still passes because
/// the address also names Đà Nẵng.
bool arrivalResultInProvince(String address, String? province) {
  if (province == null) return true;
  final folded = foldVi(address);
  final group = kArrivalProvinces[province] ?? const <String>[];
  if (group.any((n) => _containsName(folded, n))) return true;
  for (final e in kArrivalProvinces.entries) {
    if (e.key == province) continue;
    // Short forms ("hn", "hcm") are too easy to hit inside an address.
    for (final n in e.value) {
      if (n.length > 3 && _containsName(folded, n)) return false;
    }
  }
  return true;
}
