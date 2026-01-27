import 'package:flutter_naver_map/flutter_naver_map.dart';

class WalkPoint {
  final NLatLng location;
  final int bpm;
  final DateTime timestamp;

  WalkPoint({
    required this.location,
    required this.bpm,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': location.latitude,
      'lng': location.longitude,
      'bpm': bpm,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory WalkPoint.fromJson(Map<String, dynamic> json) {
    return WalkPoint(
      location: NLatLng(json['lat'], json['lng']),
      bpm: json['bpm'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
