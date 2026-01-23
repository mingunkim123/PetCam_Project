import 'dart:typed_data';
import 'package:flutter_naver_map/flutter_naver_map.dart';

enum PetPhotoCategory { none, like, dislike }

class PetPhoto {
  final String id;
  final Uint8List originalBytes;
  final Uint8List? upscaledBytes;
  final DateTime timestamp;
  final NLatLng? location;
  final bool isAiProcessed;
  final PetPhotoCategory category;

  PetPhoto({
    required this.id,
    required this.originalBytes,
    this.upscaledBytes,
    required this.timestamp,
    this.location,
    this.isAiProcessed = false,
    this.category = PetPhotoCategory.none,
  });

  PetPhoto copyWith({
    Uint8List? upscaledBytes,
    bool? isAiProcessed,
    PetPhotoCategory? category,
  }) {
    return PetPhoto(
      id: id,
      originalBytes: originalBytes,
      upscaledBytes: upscaledBytes ?? this.upscaledBytes,
      timestamp: timestamp,
      location: location,
      isAiProcessed: isAiProcessed ?? this.isAiProcessed,
      category: category ?? this.category,
    );
  }
}
