import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../models/pet_photo.dart';

class PhotoProvider with ChangeNotifier {
  final List<PetPhoto> _photos = [];
  List<PetPhoto> get photos => _photos;

  void addPhoto(Uint8List bytes) {
    final newPhoto = PetPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalBytes: bytes,
      timestamp: DateTime.now(),
    );
    _photos.add(newPhoto);
    notifyListeners();
  }

  void updateUpscaledPhoto(String id, Uint8List upscaled) {
    final index = _photos.indexWhere((p) => p.id == id);
    if (index != -1) {
      _photos[index] = _photos[index].copyWith(
        upscaledBytes: upscaled,
        isAiProcessed: true,
      );
      notifyListeners();
    }
  }
}
