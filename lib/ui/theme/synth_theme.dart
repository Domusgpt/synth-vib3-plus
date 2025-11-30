// Synth-VIB3+ Theme System
//
// Unified visual language with system-dependent colors:
// - Quantum: Cyan (#00FFFF) - Pure harmonic synthesis
// - Faceted: Magenta (#FF00FF) - Geometric hybrid synthesis
// - Holographic: Amber (#FFAA00) - Spectral rich synthesis
//
// Provides consistent glow effects, animations, and glassmorphism
// across all UI components.
//
// A Paul Phillips Manifestation
//
import 'package:flutter/material.dart';

/// System-specific color schemes
class SystemColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final String name;

  const SystemColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.name,
  });

  /// Quantum system: Pure harmonic (Cyan)
  static const quantum = SystemColors(
    primary: Color(0xFF00FFFF),   // Cyan
    secondary: Color(0xFF88CCFF), // Ice Blue
    accent: Color(0xFF0088FF),    // Electric Blue
    name: 'Quantum',
  );

  /// Faceted system: Geometric hybrid (Magenta)
  static const faceted = SystemColors(
    primary: Color(0xFFFF00FF),   // Magenta
    secondary: Color(0xFFFF88FF), // Pink
    accent: Color(0xFF8800FF),    // Deep Purple
    name: 'Faceted',
  );

  /// Holographic system: Spectral rich (Amber)
  static const holographic = SystemColors(
    primary: Color(0xFFFFAA00),   // Amber
    secondary: Color(0xFFFFCC44), // Gold
    accent: Color(0xFFFF8800),    // Orange
    name: 'Holographic',
  );

  /// Get system colors by name
  static SystemColors fromName(String name) {
    switch (name.toLowerCase()) {
      case 'quantum':
        return quantum;
      case 'faceted':
        return faceted;
      case 'holographic':
        return holographic;
      default:
        return quantum;
    }
  }
}

/// Glow intensity levels
enum GlowIntensity {
  inactive,  // Level 1
  active,    // Level 2
  engaged,   // Level 3
}

/// Theme extension for Synth-VIB3+ specific styling
class SynthTheme {
  /// Current system colors
  final SystemColors systemColors;

  /// Base dark background
  static const backgroundColor = Color(0xFF0A0A0A);
  static const panelBackground = Color(0xFF1A1A2E);
  static const cardBackground = Color(0xFF16213E);

  /// Text colors
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFCCCCCC);
  static const textDim = Color(0xFF888888);

  /// Border colors
  static const borderSubtle = Color(0x33FFFFFF); // rgba(255,255,255,0.2)
  static const borderActive = Color(0x66FFFFFF); // rgba(255,255,255,0.4)

  const SynthTheme({required this.systemColors});

  /// Get glow box shadow for given intensity
  List<BoxShadow> getGlow(GlowIntensity intensity) {
    final color = systemColors.primary;

    switch (intensity) {
      case GlowIntensity.inactive:
        return [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 0,
          ),
        ];

      case GlowIntensity.active:
        return [
          BoxShadow(
            color: color.withOpacity(0.6),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 24,
            spreadRadius: 0,
          ),
        ];

      case GlowIntensity.engaged:
        return [
          BoxShadow(
            color: color.withOpacity(0.8),
            blurRadius: 20,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 40,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 60,
            spreadRadius: 0,
          ),
        ];
    }
  }

  /// Get glassmorphic panel decoration
  BoxDecoration getGlassPanelDecoration({bool expanded = false}) {
    return BoxDecoration(
      color: panelBackground.withOpacity(0.8),
      border: Border.all(
        color: borderSubtle,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.4),
          blurRadius: 32,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 0,
          spreadRadius: 0,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Get neoskeuomorphic button decoration
  BoxDecoration getNeoskeuButtonDecoration({required bool isActive}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: isActive
          ? Border.all(color: systemColors.primary, width: 2)
          : Border.all(color: borderSubtle, width: 1),
      boxShadow: isActive
          ? [
              ...getGlow(GlowIntensity.active),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(8, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(-8, -8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(2, 2),
              ),
            ],
    );
  }

  /// Get holographic gradient for sliders/progress bars
  LinearGradient getHolographicGradient() {
    return LinearGradient(
      colors: [
        systemColors.primary,
        systemColors.secondary,
        systemColors.accent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// Get state-dependent text color
  Color getTextColor(bool isActive) {
    return isActive ? systemColors.primary : textSecondary;
  }

  /// Get state-dependent opacity
  double getOpacity(bool isActive) {
    return isActive ? 1.0 : 0.6;
  }

  /// Animation durations (consistent across app)
  static const Duration transitionStandard = Duration(milliseconds: 300);
  static const Duration transitionQuick = Duration(milliseconds: 150);
  static const Duration transitionDramatic = Duration(milliseconds: 600);
  static const Duration rippleDuration = Duration(milliseconds: 800);
  static const Duration pulseDuration = Duration(milliseconds: 500);

  /// Animation curves (Material Design standard)
  static const Curve curveStandard = Curves.easeInOutCubic;
  static const Curve curveEnter = Curves.easeOut;
  static const Curve curveExit = Curves.easeIn;

  /// Touch target sizes (accessibility)
  static const double touchTargetMinimum = 56.0;
  static const double touchTargetComfortable = 64.0;
  static const double touchTargetGenerous = 72.0;

  /// Panel dimensions
  static const double panelExpandedHeight = 300.0;
  static const double panelCollapsedHeight = 56.0;
  static const double topBezelHeight = 44.0;
  static const double sideBezelWidth = 48.0;

  /// Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;

  /// Spacing
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;

  /// Typography
  static const TextStyle textStyleHeading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    fontFamily: 'monospace',
  );

  static const TextStyle textStyleBody = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    fontFamily: 'monospace',
  );

  static const TextStyle textStyleCaption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textDim,
    fontFamily: 'monospace',
  );

  static TextStyle textStyleValue(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: color,
        fontFamily: 'monospace',
      );

  /// Z-index layers (for Stack widgets)
  static const int zIndexVisualization = 1;
  static const int zIndexXYPadOverlay = 500;
  static const int zIndexThumbPads = 600;
  static const int zIndexCollapsedBezels = 700;
  static const int zIndexExpandedPanels = 800;
  static const int zIndexOrbController = 900;
  static const int zIndexModals = 1000;
}

/// Theme provider for system color changes
class SynthThemeProvider with ChangeNotifier {
  SystemColors _currentSystem = SystemColors.quantum;

  SystemColors get currentSystem => _currentSystem;
  SynthTheme get theme => SynthTheme(systemColors: _currentSystem);

  void switchSystem(String systemName) {
    _currentSystem = SystemColors.fromName(systemName);
    notifyListeners();
    debugPrint('🎨 Theme switched to: ${_currentSystem.name}');
  }

  Color get primaryColor => _currentSystem.primary;
  Color get secondaryColor => _currentSystem.secondary;
  Color get accentColor => _currentSystem.accent;
  String get systemName => _currentSystem.name;
}

/// Extension on BuildContext for easy theme access
extension SynthThemeContext on BuildContext {
  SynthTheme get synthTheme {
    final provider = SynthThemeProvider();
    return provider.theme;
  }

  SystemColors get systemColors {
    final provider = SynthThemeProvider();
    return provider.currentSystem;
  }
}
