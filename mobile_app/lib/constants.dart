import 'package:flutter/material.dart';

// --- 1. 블루투스 통신 상수 (기존 코드) ---
class BleConstants {
  static const String deviceName = "PET_CAM_S3";
  static const String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
}

// --- 2. UI 테마 상수 (새로 추가된 코드) ---
const kPrimaryColor = Color(0xFF1A237E); // 메인 인디고 (신뢰감)
const kAccentColor = Color(0xFFFFD54F);  // 강조 앰버 (추천 뱃지)
const kBgColor = Color(0xFFF5F7FA);      // 부드러운 배경색
const kCardColor = Colors.white;         // 카드 배경색