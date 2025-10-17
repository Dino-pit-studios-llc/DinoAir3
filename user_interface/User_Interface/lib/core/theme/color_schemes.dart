// Brand & core color schemes for light and dark themes.
// Central place to adjust brand palette.
import 'package:flutter/material.dart';

// Brand base colors (design tokens)
const Color kBrandPrimary = Color(0xFF9440DD); // vivid purple
const Color kBrandSecondary = Color(0xFFF87109); // orange
// NOTE: Supplied azure hex had 7 chars (#0od8fd2). Assuming intended #00D8FD.
const Color kBrandTertiary = Color(0xFF00D8FD); // vivid azure

// Optionally expose neutral / background swatches later.

final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: kBrandPrimary,
  primary: kBrandPrimary,
  secondary: kBrandSecondary,
  tertiary: kBrandTertiary,
);

final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: kBrandPrimary,
  brightness: Brightness.dark,
  primary: kBrandPrimary,
  secondary: kBrandSecondary,
  tertiary: kBrandTertiary,
);
