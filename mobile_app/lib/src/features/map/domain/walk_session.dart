import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'walk_point.dart';

class WalkSession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<NLatLng> pathPoints;
  final List<WalkPoint> walkData;
  final int maxBpm;
  final double distance; // meters

  WalkSession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.pathPoints,
    required this.walkData,
    required this.maxBpm,
    this.distance = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'pathPoints': pathPoints
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'walkData': walkData.map((d) => d.toJson()).toList(),
      'maxBpm': maxBpm,
      'distance': distance,
    };
  }

  factory WalkSession.fromJson(Map<String, dynamic> json) {
    return WalkSession(
      id: json['id'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      pathPoints: (json['pathPoints'] as List)
          .map((p) => NLatLng(p['lat'], p['lng']))
          .toList(),
      walkData: (json['walkData'] as List)
          .map((d) => WalkPoint.fromJson(d))
          .toList(),
      maxBpm: json['maxBpm'] ?? 0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Duration get duration => endTime.difference(startTime);
}
