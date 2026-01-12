import 'package:flutter/material.dart';

// --- 1. 블루투스 통신 상수 (기존 코드) ---
class BleConstants {
  static const String deviceName = "PET_CAM_S3";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
}

// --- 2. UI 테마 상수 (Premium Revamp) ---
const kPrimaryColor = Color(0xFF2D3436); // Deep Charcoal (Premium Dark)
const kSecondaryColor = Color(0xFF6C5CE7); // Soft Purple (Accent)
const kAccentColor = Color(0xFFFF7675);  // Vibrant Coral (Highlights)
const kBgColor = Color(0xFFFDFDFD);      // Pure White / Off-White
const kSurfaceColor = Color(0xFFFFFFFF); // Card Surface

// Gradients
const kPrimaryGradient = LinearGradient(
  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

// Shadows
final kSoftShadow = BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 10,
  offset: const Offset(0, 4),
);

final kStrongShadow = BoxShadow(
  color: Colors.black.withOpacity(0.1),
  blurRadius: 20,
  offset: const Offset(0, 8),
);