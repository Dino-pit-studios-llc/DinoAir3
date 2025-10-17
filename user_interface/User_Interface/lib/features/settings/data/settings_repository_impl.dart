// Concrete implementation of SettingsRepository using SharedPreferences.
import 'package:crypto_dash/features/settings/domain/currency_preference.dart';
import 'package:crypto_dash/features/settings/domain/settings_repository.dart';
import 'package:crypto_dash/features/settings/domain/theme_mode_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  static const _kThemeModeKey = 'theme_mode';
  static const _kFiatCurrencyKey = 'fiat_currency';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  @override
  Future<AppThemeMode> getThemeMode() async {
    final p = await _prefs;
    final value = p.getString(_kThemeModeKey);
    if (value == null) return AppThemeMode.system;
    return AppThemeMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeMode.system,
    );
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) async {
    final p = await _prefs;
    await p.setString(_kThemeModeKey, mode.name);
  }

  @override
  Future<FiatCurrency> getFiatCurrency() async {
    final p = await _prefs;
    final value = p.getString(_kFiatCurrencyKey);
    if (value == null) return FiatCurrency.usd;
    return FiatCurrency.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FiatCurrency.usd,
    );
  }

  @override
  Future<void> setFiatCurrency(FiatCurrency currency) async {
    final p = await _prefs;
    await p.setString(_kFiatCurrencyKey, currency.name);
  }
}
