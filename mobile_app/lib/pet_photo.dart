import 'dart:typed_data';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PetPhoto {
  final String id;
  final Uint8List originalBytes;
  final Uint8List? upscaledBytes; // AI 변환 전엔 null
  final DateTime timestamp;
  final LatLng? location; // GPS 좌표
  final bool isAiProcessed;

  PetPhoto({
    required this.id,
    required this.originalBytes,
    this.upscaledBytes,
    required this.timestamp,
    this.location,
    this.isAiProcessed = false,
  });

  // 복사본을 만드는 메서드 (상태 변경 시 필수)
  PetPhoto copyWith({Uint8List? upscaledBytes, bool? isAiProcessed}) {
    return PetPhoto(
      id: id,
      originalBytes: originalBytes,
      upscaledBytes: upscaledBytes ?? this.upscaledBytes,
      timestamp: timestamp,
      location: location,
      isAiProcessed: isAiProcessed ?? this.isAiProcessed,
    );
  }
}