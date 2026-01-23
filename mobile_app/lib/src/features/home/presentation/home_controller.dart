import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pet_repository.dart';
import '../domain/pet_profile.dart';
import '../../gallery/domain/pet_photo.dart';

// 1. Pet Profile Controller
class PetController extends AsyncNotifier<PetProfile> {
  @override
  Future<PetProfile> build() async {
    final repository = ref.read(petRepositoryProvider);
    return repository.loadPetProfile();
  }

  Future<void> updateProfile(PetProfile newProfile) async {
    state = AsyncValue.data(newProfile);
    final repository = ref.read(petRepositoryProvider);
    await repository.savePetProfile(newProfile);
  }
}

final petControllerProvider = AsyncNotifierProvider<PetController, PetProfile>(
  PetController.new,
);

// 2. Local Photo Controller (captured photos)
class LocalPhotoController extends Notifier<List<PetPhoto>> {
  @override
  List<PetPhoto> build() {
    return [];
  }

  void addPhoto(Uint8List bytes) {
    final newPhoto = PetPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      originalBytes: bytes,
    );
    state = [newPhoto, ...state];
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

  void toggleCategory(String id, PetPhotoCategory category) {
    state = [
      for (final photo in state)
        if (photo.id == id)
          photo.copyWith(
            category: photo.category == category
                ? PetPhotoCategory.none
                : category,
          )
        else
          photo,
    ];
  }
}

final localPhotoControllerProvider =
    NotifierProvider<LocalPhotoController, List<PetPhoto>>(
      LocalPhotoController.new,
    );
