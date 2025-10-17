// Central ThemeData factories wiring color schemes + semantic extensions.
import 'package:flutter/material.dart';

import 'color_schemes.dart';
import 'semantic_colors.dart';

ThemeData buildLightTheme() {
  final scheme = lightColorScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.light,
    extensions: [buildLightSemantic(scheme)],
    // Customize component themes gradually (buttons, cards, etc.)
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

ThemeData buildDarkTheme() {
  final scheme = darkColorScheme;
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: Brightness.dark,
    extensions: [buildDarkSemantic(scheme)],
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}
