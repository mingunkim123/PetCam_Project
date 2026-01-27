import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// 🎨 PETCAM DESIGN SYSTEM - 2025 EDITION
// ═══════════════════════════════════════════════════════════════════════════

// --- Color Palette (Modern & Vibrant) ---
const kAppBackground = Color(0xFFF8F9FC); // Soft white-blue background
const kCardBackground = Color(0xFFFFFFFF);
const kSurfaceElevated = Color(0xFFF0F2F8);

// Primary Colors
const kPrimaryColor = Color(0xFF1A1D29); // Deep charcoal (softer than pure black)
const kPrimaryLight = Color(0xFF2D3142); // Lighter primary

// Brand Accent Colors
const kSecondaryColor = Color(0xFF6366F1); // Modern Indigo
const kSecondaryLight = Color(0xFF818CF8);
const kSecondaryDark = Color(0xFF4F46E5);

// Vibrant Accents
const kAccentColor = Color(0xFFFF6B6B); // Coral Red
const kAccentGreen = Color(0xFF10B981); // Emerald Green
const kAccentOrange = Color(0xFFF59E0B); // Amber Orange
const kAccentPink = Color(0xFFEC4899); // Pink
const kAccentCyan = Color(0xFF06B6D4); // Cyan
const kAccentPurple = Color(0xFF8B5CF6); // Purple

// Semantic Colors
const kSuccessColor = Color(0xFF22C55E);
const kWarningColor = Color(0xFFF59E0B);
const kErrorColor = Color(0xFFEF4444);
const kInfoColor = Color(0xFF3B82F6);

// Text Colors
const kTextPrimary = Color(0xFF1A1D29);
const kTextSecondary = Color(0xFF6B7280);
const kTextTertiary = Color(0xFF9CA3AF);
const kTextMuted = Color(0xFFD1D5DB);

// --- Gradients (Modern & Dynamic) ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kAccentGradient = LinearGradient(
  colors: [Color(0xFFFF6B6B), Color(0xFFEC4899)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kSuccessGradient = LinearGradient(
  colors: [Color(0xFF10B981), Color(0xFF22C55E)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kSunsetGradient = LinearGradient(
  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

const kOceanGradient = LinearGradient(
  colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Mesh Gradient for backgrounds
const kMeshGradient = LinearGradient(
  colors: [
    Color(0xFFF8F9FC),
    Color(0xFFEEF2FF),
    Color(0xFFF5F3FF),
    Color(0xFFFDF4FF),
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [0.0, 0.3, 0.6, 1.0],
);

// --- Typography (Inter - Clean & Modern) ---
TextTheme kAppTextTheme(TextTheme base) {
  return GoogleFonts.interTextTheme(base).copyWith(
    // Display - Hero text
    displayLarge: GoogleFonts.inter(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      color: kTextPrimary,
      letterSpacing: -1.5,
      height: 1.1,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
      letterSpacing: -1.0,
      height: 1.15,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    // Headlines
    headlineLarge: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
      letterSpacing: -0.5,
      height: 1.25,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.3,
      height: 1.3,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.2,
      height: 1.3,
    ),
    // Titles
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.2,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.1,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    // Body
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: kTextPrimary,
      letterSpacing: -0.2,
      height: 1.5,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: kTextSecondary,
      letterSpacing: -0.1,
      height: 1.45,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: kTextTertiary,
      height: 1.4,
    ),
    // Labels
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: kTextSecondary,
      letterSpacing: 0.1,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: kTextSecondary,
      letterSpacing: 0.2,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      color: kTextTertiary,
      letterSpacing: 0.3,
    ),
  );
}

// --- Spacing System (8pt grid) ---
const double kSpaceXXS = 2.0;
const double kSpaceXS = 4.0;
const double kSpaceS = 8.0;
const double kSpaceM = 12.0;
const double kSpaceL = 16.0;
const double kSpaceXL = 20.0;
const double kSpaceXXL = 24.0;
const double kSpace3XL = 32.0;
const double kSpace4XL = 40.0;
const double kSpace5XL = 48.0;
const double kSpace6XL = 64.0;

// Legacy spacing (for backward compatibility)
const double kPaddingS = 8.0;
const double kPaddingM = 16.0;
const double kPaddingL = 24.0;

// --- Border Radius ---
const double kRadiusXS = 4.0;
const double kRadiusS = 8.0;
const double kRadiusM = 12.0;
const double kRadiusL = 16.0;
const double kRadiusXL = 20.0;
const double kRadiusXXL = 24.0;
const double kRadius3XL = 28.0;
const double kRadius4XL = 32.0;
const double kRadiusFull = 999.0;

// Legacy radius (for backward compatibility)
const double kBorderRadiusL = 24.0;
const double kBorderRadiusM = 16.0;
const double kBorderRadiusS = 12.0;

// --- Shadows (Modern Elevation System) ---
// Subtle - Cards, inputs
final kShadowXS = BoxShadow(
  color: const Color(0xFF1A1D29).withOpacity(0.03),
  blurRadius: 4,
  offset: const Offset(0, 1),
);

// Light - Hover states
final kShadowS = BoxShadow(
  color: const Color(0xFF1A1D29).withOpacity(0.04),
  blurRadius: 8,
  offset: const Offset(0, 2),
);

// Medium - Elevated cards
final kShadowM = BoxShadow(
  color: const Color(0xFF1A1D29).withOpacity(0.06),
  blurRadius: 16,
  offset: const Offset(0, 4),
);

// Large - Modals, dropdowns
final kShadowL = BoxShadow(
  color: const Color(0xFF1A1D29).withOpacity(0.08),
  blurRadius: 24,
  offset: const Offset(0, 8),
);

// XLarge - Floating elements
final kShadowXL = BoxShadow(
  color: const Color(0xFF1A1D29).withOpacity(0.10),
  blurRadius: 32,
  offset: const Offset(0, 12),
);

// Colored Shadows (for accent elements)
BoxShadow kColoredShadow(Color color, {double opacity = 0.25}) => BoxShadow(
  color: color.withOpacity(opacity),
  blurRadius: 20,
  offset: const Offset(0, 8),
);

// Legacy shadows (for backward compatibility)
final kSoftShadow = BoxShadow(
  color: Colors.black.withOpacity(0.04),
  blurRadius: 12,
  offset: const Offset(0, 4),
);

final kHardShadow = BoxShadow(
  color: Colors.black.withOpacity(0.08),
  blurRadius: 24,
  offset: const Offset(0, 10),
);

// --- Animation Durations ---
const kDurationFast = Duration(milliseconds: 150);
const kDurationMedium = Duration(milliseconds: 250);
const kDurationSlow = Duration(milliseconds: 350);
const kDurationSlowest = Duration(milliseconds: 500);

// --- Animation Curves ---
const kCurveEaseOut = Curves.easeOutCubic;
const kCurveEaseIn = Curves.easeInCubic;
const kCurveEaseInOut = Curves.easeInOutCubic;
const kCurveSpring = Curves.elasticOut;
const kCurveBounce = Curves.bounceOut;

// --- Glassmorphism Decoration ---
BoxDecoration kGlassDecoration({
  Color? color,
  double borderRadius = kRadiusXL,
  double opacity = 0.7,
}) {
  return BoxDecoration(
    color: (color ?? Colors.white).withOpacity(opacity),
    borderRadius: BorderRadius.circular(borderRadius),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1.5,
    ),
    boxShadow: [kShadowM],
  );
}

// --- Modern Card Decoration ---
BoxDecoration kCardDecoration({
  Color? color,
  double borderRadius = kRadiusXL,
  List<BoxShadow>? shadows,
}) {
  return BoxDecoration(
    color: color ?? kCardBackground,
    borderRadius: BorderRadius.circular(borderRadius),
    boxShadow: shadows ?? [kShadowS, kShadowXS],
  );
}

// --- Icon Sizes ---
const double kIconXS = 14.0;
const double kIconS = 18.0;
const double kIconM = 22.0;
const double kIconL = 26.0;
const double kIconXL = 32.0;
const double kIcon2XL = 40.0;
const double kIcon3XL = 48.0;

// --- Bottom Navigation Height ---
const double kBottomNavHeight = 80.0;
const double kBottomNavIconSize = 24.0;

// --- BLE Constants (Preserved) ---
class BleConstants {
  static const String deviceName = "PET_CAM_S3";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
}
