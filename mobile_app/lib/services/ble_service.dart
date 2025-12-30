import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'ai_service.dart'; // AiService 연결

class BleService {
  static final BleService _instance = BleService._internal();
  factory BleService() => _instance;
  BleService._internal();

  final AiService _aiService = AiService();
  final String serviceUuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String dataCharUuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String cmdCharUuid = "beb5483f-36e1-4688-b7f5-ea07361b26a8";

  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _cmdCharacteristic;
  StreamSubscription? _lastValueSubscription;

  final List<int> _imageBuffer = []; // 조각 조립용 버퍼
  List<Uint8List> burstBuffer = [];  // 연속 촬영 저장소 (3장용)
  bool isBurstMode = false;          // 현재 연속 촬영 모드인지 확인

  Function(Uint8List)? onImageReceived;
  Function(bool)? onConnectionChanged;

  Future<void> connectToDevice() async {
    print("🔎 'TEST' 장치 검색 시작...");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    var subscription = FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.advertisementData.advName == "TEST") {
          _targetDevice = r.device;
          FlutterBluePlus.stopScan();
          try {
            await _targetDevice!.disconnect().catchError((e) => print("기존 연결 없음"));
            await Future.delayed(const Duration(milliseconds: 500));
            await _targetDevice!.connect(autoConnect: false);
            print("✅ 하드웨어 연결 성공: ${_targetDevice!.remoteId}");
            onConnectionChanged?.call(true);
            await _targetDevice!.requestMtu(512);
            _discoverServices();
          } catch (e) {
            print("❌ 연결 에러: $e");
            onConnectionChanged?.call(false);
          }
          break;
        }
      }
    });
  }

  void _discoverServices() async {
    if (_targetDevice == null) return;
    List<BluetoothService> services = await _targetDevice!.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toLowerCase() == serviceUuid) {
        for (var char in service.characteristics) {
          String charUuid = char.uuid.toString().toLowerCase();
          if (charUuid == dataCharUuid) _setupNotifications(char);
          if (charUuid == cmdCharUuid) _cmdCharacteristic = char;
        }
      }
    }
  }

  void _setupNotifications(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    _lastValueSubscription?.cancel();
    _lastValueSubscription = characteristic.lastValueStream.listen((value) async {
      if (value.isEmpty) return;

      // 💡 JPEG 시작(SOI) 감지 시 버퍼 초기화
      if (value.length >= 2 && value[0] == 0xFF && value[1] == 0xD8) {
        _imageBuffer.clear();
      }

      _imageBuffer.addAll(value);

      // 💡 JPEG 끝(EOI) 감지 시 사진 완성
      if (_imageBuffer.length >= 2 && _imageBuffer[_imageBuffer.length - 2] == 0xFF && _imageBuffer[_imageBuffer.length - 1] == 0xD9) {
        Uint8List completedImage = Uint8List.fromList(_imageBuffer);
        _imageBuffer.clear();
        
        if (isBurstMode) {
          burstBuffer.add(completedImage);
          print("📥 연속 촬영 이미지 수집: ${burstBuffer.length}/3");
          if (burstBuffer.length == 3) {
            print("🚀 3장 합체 완료! AI 서버 전송...");
            Uint8List? best = await _aiService.getBestCut(burstBuffer);
            if (best != null) onImageReceived?.call(best);
            burstBuffer.clear();
            isBurstMode = false;
          }
        } else {
          print("📸 단발 촬영 완료! AI 업스케일링 전송...");
          Uint8List? upscaled = await _aiService.upscaleImage(completedImage);
          onImageReceived?.call(upscaled ?? completedImage);
        }
      }
    });
  }

  Future<void> sendSnapCommand() async {
    isBurstMode = false;
    if (_cmdCharacteristic != null) await _cmdCharacteristic!.write([0x01]);
  }

  Future<void> sendBurstCommand() async {
    isBurstMode = true;
    burstBuffer.clear();
    if (_cmdCharacteristic != null) await _cmdCharacteristic!.write([0x02]);
  }
}