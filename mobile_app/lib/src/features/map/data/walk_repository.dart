import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import '../domain/walk_point.dart';
import '../domain/walk_session.dart';

class WalkRepository {
  static const String _keyWalkData = 'walk_data';
  static const String _keyPathPoints = 'path_points';
  static const String _keyIsWalking = 'is_walking';
  static const String _keyWalkHistory = 'walk_history';

  Future<void> saveWalkData(
    List<WalkPoint> walkData,
    List<NLatLng> pathPoints,
    bool isWalking,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. WalkData 저장
    final walkDataJson = walkData
        .map((point) => jsonEncode(point.toJson()))
        .toList();
    await prefs.setStringList(_keyWalkData, walkDataJson);

    // 2. PathPoints 저장
    final pathPointsJson = pathPoints
        .map(
          (point) =>
              jsonEncode({'lat': point.latitude, 'lng': point.longitude}),
        )
        .toList();
    await prefs.setStringList(_keyPathPoints, pathPointsJson);

    // 3. 상태 저장
    await prefs.setBool(_keyIsWalking, isWalking);
  }

  Future<Map<String, dynamic>> loadWalkData() async {
    final prefs = await SharedPreferences.getInstance();

    final isWalking = prefs.getBool(_keyIsWalking) ?? false;
    final walkDataList = prefs.getStringList(_keyWalkData) ?? [];
    final pathPointsList = prefs.getStringList(_keyPathPoints) ?? [];

    final List<WalkPoint> walkData = walkDataList
        .map((item) => WalkPoint.fromJson(jsonDecode(item)))
        .toList();

    final List<NLatLng> pathPoints = pathPointsList.map((item) {
      final json = jsonDecode(item);
      return NLatLng(json['lat'], json['lng']);
    }).toList();

    return {
      'isWalking': isWalking,
      'walkData': walkData,
      'pathPoints': pathPoints,
    };
  }

  Future<void> clearWalkData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyWalkData);
    await prefs.remove(_keyPathPoints);
    await prefs.remove(_keyIsWalking);
  }

  // 📜 산책 기록 저장
  Future<void> saveWalkSession(WalkSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keyWalkHistory) ?? [];

    history.add(jsonEncode(session.toJson()));
    await prefs.setStringList(_keyWalkHistory, history);
  }

  // 📜 산책 기록 불러오기
  Future<List<WalkSession>> getWalkSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keyWalkHistory) ?? [];

    return history
        .map((item) => WalkSession.fromJson(jsonDecode(item)))
        .toList()
        .reversed // 최신순 정렬
        .toList();
  }

  // 🗑️ 산책 기록 삭제
  Future<void> deleteWalkSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keyWalkHistory) ?? [];

    history.removeWhere((item) {
      final session = WalkSession.fromJson(jsonDecode(item));
      return session.id == id;
    });

    await prefs.setStringList(_keyWalkHistory, history);
  }
}

final walkRepositoryProvider = Provider<WalkRepository>((ref) {
  return WalkRepository();
});
