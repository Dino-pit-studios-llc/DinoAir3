// Semantic (domain / UX meaning) color tokens decoupled from raw palette.
// Access via: Theme.of(context).extension<SemanticColors>()
import 'package:flutter/material.dart';

class SemanticColors extends ThemeExtension<SemanticColors> {
  // highlight or active state

  const SemanticColors({
    required this.gain,
    required this.loss,
    required this.warning,
    required this.subtleBg,
    required this.accent,
  });
  final Color gain; // e.g. price up
  final Color loss; // e.g. price down
  final Color warning; // e.g. network / rate limit
  final Color subtleBg; // backgrounds / cards
  final Color accent;

  @override
  ThemeExtension<SemanticColors> copyWith({
    Color? gain,
    Color? loss,
    Color? warning,
    Color? subtleBg,
    Color? accent,
  }) =>
      SemanticColors(
        gain: gain ?? this.gain,
        loss: loss ?? this.loss,
        warning: warning ?? this.warning,
        subtleBg: subtleBg ?? this.subtleBg,
        accent: accent ?? this.accent,
      );

  @override
  ThemeExtension<SemanticColors> lerp(
    ThemeExtension<SemanticColors>? other,
    double t,
  ) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      gain: Color.lerp(gain, other.gain, t)!,
      loss: Color.lerp(loss, other.loss, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      subtleBg: Color.lerp(subtleBg, other.subtleBg, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }
}

// Light / Dark presets (can refine with design later)
SemanticColors buildLightSemantic(ColorScheme scheme) => SemanticColors(
      gain: Colors.green.shade600,
      loss: Colors.red.shade600,
      warning: Colors.orange.shade600,
      subtleBg: scheme.surfaceContainerLow,
      accent: scheme.secondary,
    );

SemanticColors buildDarkSemantic(ColorScheme scheme) => SemanticColors(
      gain: Colors.greenAccent.shade400,
      loss: Colors.redAccent.shade200,
      warning: Colors.orange.shade400,
      subtleBg: scheme.surfaceContainer,
      accent: scheme.secondary,
    );
