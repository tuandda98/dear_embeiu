import 'package:dear_embeiu/l10n/app_localizations.dart';
import 'package:dear_embeiu/providers/decision_provider.dart';
import 'package:dear_embeiu/widgets/decision_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _CountingDecisionProvider extends DecisionProvider {
  int refreshes = 0;

  @override
  void refreshDay() => refreshes++;
}

/// decision-wheel BUG-2: at 0:00 the card body must rebuild (and so ask the
/// provider for the new day) — a const body under MidnightBuilder never did.
void main() {
  testWidgets('DecisionCard re-runs refreshDay when the day rolls over', (
    tester,
  ) async {
    final provider = _CountingDecisionProvider();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ChangeNotifierProvider<DecisionProvider>.value(
          value: provider,
          child: const Scaffold(body: DecisionCard()),
        ),
      ),
    );
    final before = provider.refreshes;
    expect(before, greaterThan(0));
    // MidnightBuilder's timer fires within 24 h of the real clock.
    await tester.pump(const Duration(hours: 25));
    await tester.pump();
    expect(provider.refreshes, greaterThan(before));
  });
}
