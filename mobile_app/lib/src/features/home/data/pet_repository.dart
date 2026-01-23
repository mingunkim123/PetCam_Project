import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/pet_profile.dart';

class PetRepository {
  static const String _storageKey = 'pet_profile_data';

  Future<PetProfile> loadPetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString != null) {
      return PetProfile.fromJson(jsonDecode(jsonString));
    }
    return PetProfile.empty();
  }

  Future<void> savePetProfile(PetProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profile.toJson()));
  }
}

final petRepositoryProvider = Provider<PetRepository>((ref) => PetRepository());
