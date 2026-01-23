import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- Color Palette (Premium & Soft) ---
const kAppBackground = Color(0xFFF2F2F7); // Apple Health Light Gray Background
const kCardBackground = Color(0xFFFFFFFF);
const kPrimaryColor = Color(0xFF000000); // Minimalist Black
const kSecondaryColor = Color(0xFF5E5CE6); // Indigo/Purple Accent
const kAccentColor = Color(0xFFFF375F); // Pink/Red Accent
const kSuccessColor = Color(0xFF30D158);
const kWarningColor = Color(0xFFFF9F0A);
const kErrorColor = Color(0xFFFF453A);

const kTextPrimary = Color(0xFF000000);
const kTextSecondary = Color(0xFF8E8E93);
const kTextTertiary = Color(0xFFC7C7CC);

// --- Gradients ---
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF5E5CE6), Color(0xFFBF5AF2)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// --- Typography (Inter) ---
TextTheme kAppTextTheme(TextTheme base) {
  return GoogleFonts.interTextTheme(base).copyWith(
    displayLarge: GoogleFonts.inter(
      fontSize: 34,
      fontWeight: FontWeight.bold,
      color: kTextPrimary,
      letterSpacing: -0.4,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 30,
      fontWeight: FontWeight.w700,
      color: kTextPrimary,
      letterSpacing: -0.4,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
      letterSpacing: -0.4,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: kTextPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 17,
      fontWeight: FontWeight.w400,
      color: kTextPrimary,
      letterSpacing: -0.4,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: kTextSecondary,
      letterSpacing: -0.2,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: kTextSecondary,
    ),
  );
}

// --- Spacing & Radius ---
const double kPaddingS = 8.0;
const double kPaddingM = 16.0;
const double kPaddingL = 24.0;
const double kBorderRadiusL = 24.0;
const double kBorderRadiusM = 16.0;
const double kBorderRadiusS = 12.0;

// --- Shadows ---
final kSoftShadow = BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
  offset: const Offset(0, 4),
);

final kHardShadow = BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 20,
  offset: const Offset(0, 10),
);

// --- BLE Constants (Preserved) ---
class BleConstants {
  static const String deviceName = "PET_CAM_S3";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
}
