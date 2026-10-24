import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dear_embeiu/utils/arrival_place_query.dart';

/// Feature arrival stage 2: query shortening (D20, spike §6.8). Cases = the 20
/// addresses of `project/features/arrival/spike-data/addrs.tsv` + the 4 alley
/// probes, expected = "number + street, province" (the form that reached 75%).
void main() {
  const expected = <int, String>{
    1: '78 Giải Phóng, Hà Nội',
    2: '1 Đại Cồ Việt, Hà Nội',
    3: '1 Tràng Tiền, Hà Nội',
    4: '58 Quốc Tử Giám, Hà Nội',
    5: '40 Tràng Thi, Hà Nội',
    6: '144 Xuân Thủy, Hà Nội',
    7: '54 Liễu Giai, Hà Nội',
    8: '120 Lê Duẩn, Hà Nội',
    9: '135 Nam Kỳ Khởi Nghĩa, TP.HCM',
    10: '1 Công xã Paris, TP.HCM',
    11: '2 Công xã Paris, TP.HCM',
    12: 'Chợ Bến Thành, Lê Lợi, TP.HCM',
    13: '201B Nguyễn Chí Thanh, TP.HCM',
    14: '268 Lý Thường Kiệt, TP.HCM',
    15: '720A Điện Biên Phủ, TP.HCM',
    16: '7 Công trường Lam Sơn, TP.HCM',
    17: '124 Hải Phòng, Đà Nẵng',
    18: '16 Lê Lợi, Thành phố Huế',
    19: 'Khu II, đường 3/2, Cần Thơ',
    20: '75 Lương Khánh Thiện, Hải Phòng',
  };
  const provinceOf = {
    'HN': 'ha noi',
    'HCM': 'ho chi minh',
    'DN': 'da nang',
    'Huế': 'hue',
    'CT': 'can tho',
    'HP': 'hai phong',
  };

  List<List<String>> rows(String file) =>
      File('project/features/arrival/spike-data/$file')
          .readAsLinesSync()
          .where((l) => l.trim().isNotEmpty)
          .map((l) => l.split('\t'))
          .toList();

  group('shortenArrivalPlaceQuery — spike table', () {
    for (final r in rows('addrs.tsv')) {
      final id = int.parse(r[0]);
      test('#$id ${r[3]}', () {
        final q = shortenArrivalPlaceQuery(r[3]);
        expect(q.text, expected[id]);
        expect(q.province, provinceOf[r[1]]);
        expect(q.alley, isFalse); // "đường 3/2" is a street, not an alley
      });
    }
    test('alley probes send the alley mouth, flagged approximate', () {
      final out = {
        for (final r in rows('probes.tsv'))
          r[0]: shortenArrivalPlaceQuery(r[3]),
      };
      expect(out['P1']!.text, '45 Lê Văn Sỹ, TP.HCM');
      expect(out['P2']!.text, '45 Lê Văn Sỹ, TP.HCM');
      expect(out['P3']!.text, '25 Tạ Quang Bửu, Hà Nội');
      expect(out['P4']!.text, '102 Nguyễn Chí Thanh, Hà Nội');
      expect(out.values.every((q) => q.alley), isTrue);
    });
  });

  group('shortenArrivalPlaceQuery — other shapes', () {
    test('no province: only marked ward/district parts go', () {
      final q = shortenArrivalPlaceQuery('12 Nguyễn Trãi, Thanh Xuân, P.5');
      expect(q.text, '12 Nguyễn Trãi, Thanh Xuân');
      expect(q.province, isNull);
    });
    test('trailing country, prefixes, short forms', () {
      expect(
        shortenArrivalPlaceQuery(
          '1 Đại Cồ Việt, Phường Bạch Mai, Thành phố Hà Nội, Việt Nam',
        ).text,
        '1 Đại Cồ Việt, Thành phố Hà Nội',
      );
      expect(
        shortenArrivalPlaceQuery('5 Lê Lợi, Q.1, TPHCM').province,
        'ho chi minh',
      );
      expect(
        shortenArrivalPlaceQuery('5 Lê Lợi, Q1, Sài Gòn').text,
        '5 Lê Lợi, Sài Gòn',
      );
      expect(
        shortenArrivalPlaceQuery('Chung cư A, 12 Nguyễn Trãi, Hà Nội').text,
        '12 Nguyễn Trãi, Hà Nội',
      );
      expect(
        shortenArrivalPlaceQuery('Hẻm 45/12/3 Lê Văn Sỹ, TP.HCM').text,
        '45 Lê Văn Sỹ, TP.HCM',
      );
      expect(shortenArrivalPlaceQuery('  ').text, '');
      expect(
        shortenArrivalPlaceQuery('Tây Ninh').province,
        isNull,
      ); // one part = the text
      expect(arrivalProvinceOf('Tây Ninh'), 'tay ninh');
      expect(arrivalProvinceOf('Bình Dương'), 'ho chi minh'); // merged 2025
    });
  });

  group('arrivalResultInProvince', () {
    test('wrong province dropped, merged / unnamed / street-named kept', () {
      // Spike #1 full query went to Ninh Bình.
      expect(
        arrivalResultInProvince(
          '78 Giải Phóng, P. Đông A, Ninh Bình, Việt Nam',
          'ha noi',
        ),
        isFalse,
      );
      expect(
        arrivalResultInProvince(
          '78 Ngõ 75 Giải Phóng, P. Bạch Mai, Thành Phố Hà Nội, Việt Nam',
          'ha noi',
        ),
        isTrue,
      );
      expect(
        arrivalResultInProvince(
          '124 Hải Phòng, P. Hải Châu, Đà Nẵng',
          'da nang',
        ),
        isTrue,
      );
      expect(
        arrivalResultInProvince('Dĩ An, Bình Dương', 'ho chi minh'),
        isTrue,
      );
      expect(
        arrivalResultInProvince(
          '135 Nam Kỳ Khởi Nghĩa, Vũng Tàu',
          'ho chi minh',
        ),
        isTrue,
      );
      expect(arrivalResultInProvince('12 Lê Lợi', 'hue'), isTrue);
      expect(arrivalResultInProvince('Anywhere, Hà Nội', null), isTrue);
      expect(
        arrivalResultInProvince('1 Main St, Hanoi, Vietnam', 'ha noi'),
        isTrue,
      );
    });
    test('foldVi', () {
      expect(foldVi('Thành Phố Hồ Chí Minh'), 'thanh pho ho chi minh');
      expect(foldVi('Đắk Lắk'), 'dak lak');
      expect(foldVi('TP.HCM'), 'tp hcm');
    });
  });
}
