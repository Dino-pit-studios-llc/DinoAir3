import 'currency_preference.dart';
import 'theme_mode_preference.dart';

/// Abstraction over preference storage.
abstract class SettingsRepository {
  Future<AppThemeMode> getThemeMode();
  Future<void> setThemeMode(AppThemeMode mode);
  Future<FiatCurrency> getFiatCurrency();
  Future<void> setFiatCurrency(FiatCurrency currency);
}
