import 'package:flutter/material.dart';
import '../models/pet_photo.dart';
import 'dart:typed_data';

class PhotoProvider with ChangeNotifier {
  final List<PetPhoto> _photos = [];

  List<PetPhoto> get photos => _photos;

  // 새로운 사진 추가 (BLE 수신 시 호출)
  void addPhoto(Uint8List bytes, {double? lat, double? lng}) {
    final newPhoto = PetPhoto(
      id: DateTime.now().toString(),
      originalBytes: bytes,
      timestamp: DateTime.now(),
      location: (lat != null && lng != null) ? LatLng(lat, lng) : null,
    );
    _photos.add(newPhoto);
    notifyListeners(); // 이 앱을 듣고 있는 모든 화면에 "바뀌었어!"라고 알림
  }

  // AI 업스케일링 결과 업데이트
  void updateUpscaledPhoto(String id, Uint8List upscaledBytes) {
    final index = _photos.indexWhere((p) => p.id == id);
    if (index != -1) {
      _photos[index] = _photos[index].copyWith(
        upscaledBytes: upscaledBytes,
        isAiProcessed: true,
      );
      notifyListeners();
    }
  }
}