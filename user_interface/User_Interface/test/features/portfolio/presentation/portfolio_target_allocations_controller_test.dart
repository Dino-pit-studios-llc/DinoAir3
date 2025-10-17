import 'dart:convert';

import 'package:crypto_dash/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:crypto_dash/main.dart' as app_main;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef _ContainerWithPrefs = ({
  ProviderContainer container,
  SharedPreferences prefs,
});

Future<_ContainerWithPrefs> _createContainer({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [app_main.sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  return (container: container, prefs: prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PortfolioTargetAllocationsController', () {
    test('build returns empty map when no stored targets', () async {
      final setup = await _createContainer();
      addTearDown(() async {
        await setup.prefs.clear();
        setup.container.dispose();
      });

      final result = await setup.container.read(
        portfolioTargetAllocationsProvider.future,
      );

      expect(result, isEmpty);
    });

    test('build recovers from malformed json payload', () async {
      const malformed = '{"btc": {"bad": "structure"}}';
      final setup = await _createContainer(
        initialValues: {'portfolio.target_allocations_v1': malformed},
      );
      addTearDown(() async {
        await setup.prefs.clear();
        setup.container.dispose();
      });

      final result = await setup.container.read(
        portfolioTargetAllocationsProvider.future,
      );

      expect(result, isEmpty);
    });

    test(
      'saveAll clamps values between 0 and 1 and persists cleaned map',
      () async {
        final setup = await _createContainer();
        addTearDown(() async {
          await setup.prefs.clear();
          setup.container.dispose();
        });

        final controller = setup.container.read(
          portfolioTargetAllocationsProvider.notifier,
        );

        await controller.future;

        await controller.saveAll({
          'btc': 0.45,
          'eth': 1.2, // clamped to 1.0
          'doge': -0.1, // removed
          'ada': double.nan, // removed
        });

        final raw = setup.prefs.getString('portfolio.target_allocations_v1');
        expect(raw, isNotNull);

        final decoded = jsonDecode(raw!) as Map<String, dynamic>;
        expect(decoded.keys, containsAll(['btc', 'eth']));
        expect(decoded['btc'], closeTo(0.45, 1e-9));
        expect(decoded['eth'], closeTo(1.0, 1e-9));
        expect(decoded.containsKey('doge'), isFalse);

        final refreshedState = setup.container.read(
          portfolioTargetAllocationsProvider,
        );
        expect(refreshedState.hasValue, isTrue);
        final refreshed = refreshedState.requireValue;
        expect(refreshed.keys, containsAll(['btc', 'eth']));
        expect(refreshed['btc'], isNotNull);
        expect(refreshed['btc']!, closeTo(0.45, 1e-9));
        expect(refreshed['eth'], isNotNull);
        expect(refreshed['eth']!, closeTo(1.0, 1e-9));
      },
    );

    test('setTarget applies clamps and removeTarget deletes entries', () async {
      final setup = await _createContainer();
      addTearDown(() async {
        await setup.prefs.clear();
        setup.container.dispose();
      });

      final controller = setup.container.read(
        portfolioTargetAllocationsProvider.notifier,
      );

      await controller.future;

      await controller.setTarget('btc', 0.3);
      await controller.setTarget('eth', 2.5);
      await controller.setTarget('doge', -0.5); // should not add

      var targets = setup.container
          .read(portfolioTargetAllocationsProvider)
          .requireValue;
      expect(targets['btc'], isNotNull);
      expect(targets['btc']!, closeTo(0.3, 1e-9));
      expect(targets['eth'], isNotNull);
      expect(targets['eth']!, closeTo(1.0, 1e-9));

      await controller.removeTarget('btc');
      await controller.setTarget('eth', 0);

      targets = setup.container
          .read(portfolioTargetAllocationsProvider)
          .requireValue;
      expect(targets, isEmpty);
    });
  });
}
