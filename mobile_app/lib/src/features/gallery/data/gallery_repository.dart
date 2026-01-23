import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/ai_service.dart';
import '../../gallery/domain/pet_photo.dart';

class GalleryRepository {
  final AiService _aiService;

  GalleryRepository(this._aiService);

  Future<List<dynamic>> fetchPhotos({int skip = 0, int limit = 20}) async {
    return _aiService.fetchPhotos(skip: skip, limit: limit);
  }

  Future<bool> deletePhoto(String id) async {
    return _aiService.deletePhoto(id);
  }

  String getPhotoUrl(String id) {
    return _aiService.getPhotoUrl(id);
  }

  Future<Uint8List?> downloadPhoto(String url) {
    return _aiService.downloadPhoto(url);
  }
}

final galleryRepositoryProvider = Provider<GalleryRepository>((ref) {
  // AiService is now in src/services, make sure to import it correctly
  // Assuming aiServiceProvider is still in riverpod_providers.dart for now,
  // but we should eventually move providers too.
  // For now, let's instantiate AiService directly or use the one from service layer if it was a singleton.
  // Better yet, let's use the provider if we can find it, or just new it up since it's stateless mostly.
  return GalleryRepository(AiService());
});
