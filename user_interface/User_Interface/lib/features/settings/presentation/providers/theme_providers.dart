import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../settings/data/settings_repository_impl.dart';
import '../../../settings/domain/currency_preference.dart';
import '../../../settings/domain/settings_repository.dart';
import '../../../settings/domain/theme_mode_preference.dart';

// Repository provider (simple DI)
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl();
});

// Controller to manage theme mode persistence
class ThemeModeController extends Notifier<AppThemeMode> {
  late final SettingsRepository _repo;

  @override
  AppThemeMode build() {
    _repo = ref.read(settingsRepositoryProvider);
    _load();
    return AppThemeMode.system;
  }

  Future<void> _load() async {
    state = await _repo.getThemeMode();
  }

  Future<void> set(AppThemeMode mode) async {
    state = mode;
    await _repo.setThemeMode(mode);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, AppThemeMode>(
  ThemeModeController.new,
);

extension AppThemeModeX on AppThemeMode {
  ThemeMode get material => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };
}

// Expose ThemeData providers (optional convenience)
final lightThemeProvider = Provider((_) => buildLightTheme());
final darkThemeProvider = Provider((_) => buildDarkTheme());

// Fiat currency controller (placeholder for future settings UI)
class FiatCurrencyController extends Notifier<FiatCurrency> {
  late final SettingsRepository _repo;

  @override
  FiatCurrency build() {
    _repo = ref.read(settingsRepositoryProvider);
    _load();
    return FiatCurrency.usd;
  }

  Future<void> _load() async {
    state = await _repo.getFiatCurrency();
  }

  Future<void> set(FiatCurrency currency) async {
    state = currency;
    await _repo.setFiatCurrency(currency);
  }
}

final fiatCurrencyControllerProvider =
    NotifierProvider<FiatCurrencyController, FiatCurrency>(
  FiatCurrencyController.new,
);
