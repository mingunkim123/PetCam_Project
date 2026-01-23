import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/gallery_repository.dart';
import '../domain/pet_photo.dart';

// 1. Server Photos State & Controller
class ServerPhotosState {
  final List<dynamic> photos;
  final bool isLoading;
  final bool hasMore;
  final int page;

  ServerPhotosState({
    required this.photos,
    required this.isLoading,
    required this.hasMore,
    required this.page,
  });

  ServerPhotosState.initial()
    : photos = [],
      isLoading = false,
      hasMore = true,
      page = 0;

  ServerPhotosState copyWith({
    List<dynamic>? photos,
    bool? isLoading,
    bool? hasMore,
    int? page,
  }) {
    return ServerPhotosState(
      photos: photos ?? this.photos,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
    );
  }
}

class GalleryController extends Notifier<ServerPhotosState> {
  static const int _limit = 20;

  @override
  ServerPhotosState build() {
    Future.microtask(() => fetchMore());
    return ServerPhotosState.initial();
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final repository = ref.read(galleryRepositoryProvider);
      final newPhotos = await repository.fetchPhotos(
        skip: state.page * _limit,
        limit: _limit,
      );

      if (newPhotos.isEmpty) {
        state = state.copyWith(isLoading: false, hasMore: false);
      } else {
        state = state.copyWith(
          photos: [...state.photos, ...newPhotos],
          isLoading: false,
          page: state.page + 1,
          hasMore: newPhotos.length == _limit,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      debugPrint("Error fetching photos: $e");
    }
  }

  Future<void> refresh() async {
    state = ServerPhotosState.initial();
    await fetchMore();
  }
}

final galleryControllerProvider =
    NotifierProvider<GalleryController, ServerPhotosState>(
      GalleryController.new,
    );

// 2. Photo Category Controller
class PhotoCategoryController extends Notifier<Map<String, PetPhotoCategory>> {
  static const String _storageKey = 'photo_categories';

  @override
  Map<String, PetPhotoCategory> build() {
    _loadCategories();
    return {};
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      state = jsonMap.map((key, value) {
        return MapEntry(
          key,
          PetPhotoCategory.values.firstWhere(
            (e) => e.toString() == value,
            orElse: () => PetPhotoCategory.none,
          ),
        );
      });
    }
  }

  Future<void> toggleCategory(String id, PetPhotoCategory category) async {
    final current = state[id] ?? PetPhotoCategory.none;
    final newCategory = current == category ? PetPhotoCategory.none : category;

    state = {...state, id: newCategory};
    await _saveCategories();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, String> jsonMap = state.map(
      (key, value) => MapEntry(key, value.toString()),
    );
    await prefs.setString(_storageKey, jsonEncode(jsonMap));
  }
}

final photoCategoryControllerProvider =
    NotifierProvider<PhotoCategoryController, Map<String, PetPhotoCategory>>(
      PhotoCategoryController.new,
    );
