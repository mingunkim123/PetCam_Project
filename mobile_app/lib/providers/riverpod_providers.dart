import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_profile.dart';
import '../models/pet_photo.dart';
import '../services/ai_service.dart';

// AI Service Provider
final aiServiceProvider = Provider<AiService>((ref) => AiService());

// Pet Profile Notifier (AsyncNotifier for async loading)
class PetNotifier extends AsyncNotifier<PetProfile> {
  static const String _storageKey = 'pet_profile_data';

  @override
  Future<PetProfile> build() async {
    return _loadProfile();
  }

  Future<PetProfile> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        return PetProfile.fromJson(jsonMap);
      } else {
        return PetProfile.empty();
      }
    } catch (e) {
      // If error, return empty profile or rethrow
      return PetProfile.empty();
    }
  }

  Future<void> updateProfile(PetProfile newProfile) async {
    // Optimistically update state
    state = AsyncValue.data(newProfile);
    await _saveProfile(newProfile);
  }

  Future<void> _saveProfile(PetProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(profile.toJson());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint("Error saving profile: $e");
    }
  }
}

final petProfileProvider = AsyncNotifierProvider<PetNotifier, PetProfile>(
  PetNotifier.new,
);

// Photo Notifier (Sync list is fine, so Notifier)
class PhotoNotifier extends Notifier<List<PetPhoto>> {
  @override
  List<PetPhoto> build() {
    return [];
  }

  void addPhoto(Uint8List bytes) {
    final newPhoto = PetPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      originalBytes: bytes,
      timestamp: DateTime.now(),
    );
    state = [...state, newPhoto];
  }

  void updateUpscaledPhoto(String id, Uint8List upscaled) {
    state = [
      for (final photo in state)
        if (photo.id == id)
          photo.copyWith(upscaledBytes: upscaled, isAiProcessed: true)
        else
          photo,
    ];
  }
}

final photoProvider = NotifierProvider<PhotoNotifier, List<PetPhoto>>(
  PhotoNotifier.new,
);

// Server Photos Provider
final serverPhotosProvider = FutureProvider.autoDispose<List<dynamic>>((
  ref,
) async {
  final aiService = ref.watch(aiServiceProvider);
  return await aiService.fetchPhotos();
});
