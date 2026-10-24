import '../l10n/app_l10n.dart';

class CounterData {
  final int days;
  final int months;
  final int years;

  CounterData({
    required this.days,
    required this.months,
    required this.years,
  });

  // Calculate from anniversary date
  static CounterData calculateFromAnniversary(DateTime anniversaryDate) {
    final now = DateTime.now();
    final difference = now.difference(anniversaryDate);

    int totalDays = difference.inDays;
    int years = 0;
    int months = 0;
    int days = totalDays;

    // Calculate years
    years = totalDays ~/ 365;
    totalDays = totalDays % 365;

    // Calculate months (approximate, using 30 days per month)
    months = totalDays ~/ 30;
    days = totalDays % 30;

    return CounterData(
      days: days,
      months: months,
      years: years,
    );
  }

  // Get formatted string
  String toFormattedString() {
    return AppL10n.strings.counterDuration(years, months, days);
  }
}

