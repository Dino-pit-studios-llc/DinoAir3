import 'package:crypto_dash/features/portfolio/presentation/providers/portfolio_providers.dart';
import 'package:crypto_dash/main.dart' as app_main;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<({ProviderContainer container, SharedPreferences prefs})>
    _createContainer(Map<String, Object> initialValues) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [app_main.sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  return (container: container, prefs: prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PortfolioSortController', () {
    test('defaults to valueDesc when preference missing', () async {
      final setup = await _createContainer(const {});
      addTearDown(() async {
        await setup.prefs.clear();
        setup.container.dispose();
      });

      final sortOption = setup.container.read(portfolioSortOptionProvider);
      expect(sortOption, PortfolioSortOption.valueDesc);
    });

    test('restores stored value and persists updates', () async {
      final setup = await _createContainer(const {
        'portfolio.sort_option': 'nameAsc',
      });
      addTearDown(() async {
        await setup.prefs.clear();
        setup.container.dispose();
      });

      final container = setup.container;
      final notifier = container.read(portfolioSortOptionProvider.notifier);

      expect(
        container.read(portfolioSortOptionProvider),
        PortfolioSortOption.nameAsc,
      );

      notifier.select(PortfolioSortOption.valueDesc);
      await Future<void>.value(); // allow async prefs write

      expect(
        container.read(portfolioSortOptionProvider),
        PortfolioSortOption.valueDesc,
      );
      expect(
        setup.prefs.getString('portfolio.sort_option'),
        equals(PortfolioSortOption.valueDesc.name),
      );
    });
  });
}
