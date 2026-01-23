import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeartRateData {
  final int bpm;
  final String emotion;

  HeartRateData({required this.bpm, required this.emotion});
}

class HeartRateService {
  final _controller = StreamController<HeartRateData>.broadcast();
  Timer? _timer;
  final Random _random = Random();

  Stream<HeartRateData> get heartRateStream => _controller.stream;

  void startMonitoring() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // 60 ~ 140 BPM 랜덤 생성
      final bpm = 60 + _random.nextInt(81);
      final emotion = getEmotion(bpm);
      _controller.add(HeartRateData(bpm: bpm, emotion: emotion));
    });
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  String getEmotion(int bpm) {
    if (bpm < 80) {
      return "Relaxed";
    } else if (bpm < 110) {
      return "Happy";
    } else {
      return "Excited";
    }
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}

final heartRateServiceProvider = Provider<HeartRateService>((ref) {
  final service = HeartRateService();
  ref.onDispose(service.dispose);
  service.startMonitoring();
  return service;
});

final heartRateStreamProvider = StreamProvider<HeartRateData>((ref) {
  final service = ref.watch(heartRateServiceProvider);
  return service.heartRateStream;
});
