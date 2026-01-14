import 'dart:async';
import 'dart:typed_data';
import 'dart:convert'; // utf8 decoding
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart'; // GPS 패키지 추가
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
  int _expectedSize = 0; // 예상되는 이미지 크기

  // List<Uint8List> burstBuffer = []; // ❌ 더 이상 앱에서 모으지 않음 (펌웨어가 골라줌)
  bool isBurstMode = false; // 현재 연속 촬영 모드인지 확인
  bool isPreviewMode = false; // 미리보기 모드 확인

  Function(Uint8List)? onImageReceived;
  Function(Uint8List)? onPreviewReceived; // 미리보기 수신 콜백
  Function(bool)? onConnectionChanged;

  Future<void> connectToDevice() async {
    print("🔎 'TEST' 장치 검색 시작... (15초 대기)");
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    var subscription = FlutterBluePlus.onScanResults.listen((results) async {
      for (ScanResult r in results) {
        // [디버깅] 검색된 기기 정보 상세 출력
        print("📡 발견: ${r.device.platformName} (${r.device.remoteId})");
        print("   UUIDs: ${r.advertisementData.serviceUuids}");

        // 1. 이름으로 찾기 ("TEST")
        bool nameMatch =
            r.advertisementData.advName == "TEST" ||
            r.device.platformName == "TEST";

        // 2. 서비스 UUID로 찾기 (더 확실함)
        bool uuidMatch = r.advertisementData.serviceUuids.contains(
          Guid(serviceUuid),
        );

        if (nameMatch || uuidMatch) {
          print("✅ 타겟 장치 발견! (Name: $nameMatch, UUID: $uuidMatch)");
          _targetDevice = r.device;
          FlutterBluePlus.stopScan();
          try {
            await _targetDevice!.disconnect().catchError(
              (e) => print("기존 연결 없음"),
            );
            await Future.delayed(const Duration(milliseconds: 500));

            // 💡 연결 상태 리스너 등록 (연결 끊김 감지용)
            _targetDevice!.connectionState.listen((
              BluetoothConnectionState state,
            ) {
              print("🔌 연결 상태 변경: $state");
              if (state == BluetoothConnectionState.disconnected) {
                onConnectionChanged?.call(false);
                _cmdCharacteristic = null; // 특성 초기화
              } else if (state == BluetoothConnectionState.connected) {
                onConnectionChanged?.call(true);
              }
            });

            await _targetDevice!.connect(autoConnect: false);
            print("✅ 하드웨어 연결 성공: ${_targetDevice!.remoteId}");

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
    _lastValueSubscription = characteristic.lastValueStream.listen((
      value,
    ) async {
      if (value.isEmpty) return;

      // 1. 헤더 감지 (SIZE:xxxxx)
      try {
        String str = utf8.decode(value);
        if (str.startsWith("SIZE:")) {
          String sizeStr = str.substring(5);
          _expectedSize = int.tryParse(sizeStr) ?? 0;
          _imageBuffer.clear();
          print("📥 [BLE] 이미지 수신 시작! 예상 크기: $_expectedSize bytes");
          return; // 헤더는 이미지 데이터가 아니므로 리턴
        }
      } catch (e) {
        // utf8 디코딩 실패 시 그냥 바이너리 데이터로 간주하고 진행
      }

      // 2. 데이터 누적
      _imageBuffer.addAll(value);

      // 진행률 로그 (너무 자주 찍히면 주석 처리)
      // print("📥 [BLE] Progress: ${_imageBuffer.length} / $_expectedSize");

      // 3. 완료 체크 (예상 크기 도달 시)
      if (_expectedSize > 0 && _imageBuffer.length >= _expectedSize) {
        print("📦 이미지 수신 완료! (Total: ${_imageBuffer.length} bytes)");

        Uint8List completedImage = Uint8List.fromList(_imageBuffer);
        _imageBuffer.clear();
        _expectedSize = 0; // 초기화

        if (isPreviewMode) {
          print("📸 미리보기 이미지 처리");
          onPreviewReceived?.call(completedImage);
          isPreviewMode = false;
        } else if (isBurstMode) {
          // 💡 [수정] 펌웨어가 이미 Best Cut을 골라서 1장만 보내주므로, 3장을 기다릴 필요 없음!
          print("📸 연속 촬영(Best Cut) 수신 완료! AI 업스케일링 전송...");
          Uint8List? upscaled = await _aiService.upscaleImage(completedImage);
          onImageReceived?.call(upscaled ?? completedImage);
          isBurstMode = false;
        } else {
          print("📸 단발 촬영 완료! AI 업스케일링 전송...");
          Uint8List? upscaled = await _aiService.upscaleImage(completedImage);
          onImageReceived?.call(upscaled ?? completedImage);
        }
      }
    });
  }

  // 📍 현재 위치 가져오기 헬퍼
  Future<Position?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print("❌ 위치 가져오기 실패: $e");
      return null;
    }
  }

  // 📦 GPS 데이터를 바이트로 변환 (Double 8byte * 2 = 16byte)
  List<int> _packGpsData(double lat, double lng) {
    var buffer = ByteData(16);
    buffer.setFloat64(0, lat, Endian.little); // Little Endian (ESP32)
    buffer.setFloat64(8, lng, Endian.little);
    return buffer.buffer.asUint8List().toList();
  }

  Future<void> sendSnapCommand() async {
    isBurstMode = false;
    if (_cmdCharacteristic != null) {
      // 1. 위치 가져오기
      Position? position = await _getCurrentLocation();
      double lat = position?.latitude ?? 0.0;
      double lng = position?.longitude ?? 0.0;
      print("📍 전송할 위치: $lat, $lng");

      // 2. 패킷 생성: [CMD(1)] + [Lat(8)] + [Lng(8)]
      List<int> packet = [0x01];
      packet.addAll(_packGpsData(lat, lng));

      await _cmdCharacteristic!.write(packet);
    }
  }

  Future<void> sendBurstCommand() async {
    isBurstMode = true;
    // burstBuffer.clear(); // 사용 안 함
    if (_cmdCharacteristic != null) {
      // 1. 위치 가져오기
      Position? position = await _getCurrentLocation();
      double lat = position?.latitude ?? 0.0;
      double lng = position?.longitude ?? 0.0;
      print("📍 전송할 위치(연속): $lat, $lng");

      // 2. 패킷 생성: [CMD(1)] + [Lat(8)] + [Lng(8)]
      List<int> packet = [0x02];
      packet.addAll(_packGpsData(lat, lng));

      print("📤 [BLE] 연속 촬영 명령 전송 (0x02 + GPS)");
      await _cmdCharacteristic!.write(packet, withoutResponse: true);
    }
  }

  // 📸 미리보기 요청 (0x03) - 미리보기는 GPS 필요 없음
  Future<void> sendPreviewCommand() async {
    if (_cmdCharacteristic == null) {
      print("❌ 명령 채널이 연결되지 않음");
      return;
    }
    try {
      isPreviewMode = true; // 미리보기 모드 활성화
      print("📤 [BLE] 미리보기 요청 전송 (0x03)");
      await _cmdCharacteristic!.write([0x03], withoutResponse: true);
    } catch (e) {
      print("❌ 전송 실패: $e");
      isPreviewMode = false;
      onConnectionChanged?.call(false); // 연결 끊김으로 간주
    }
  }
}
