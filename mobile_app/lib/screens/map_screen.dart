import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

// 💡 클래스 이름을 main.dart와 동일하게 MapScreen으로 수정했습니다.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 1. 상태 변수 및 컨트롤러
  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  List<NLatLng> _pathPoints = []; // 산책 경로 좌표 리스트
  bool _isWalking = false; // 산책 중 상태 플래그

  @override
  void dispose() {
    // 💡 메모리 누수 방지를 위해 스트림 해제 (전기전자 전공자라면 필수 리소스 관리!)
    _positionStream?.cancel(); 
    super.dispose();
  }

  // 2. 위치 권한 확인 및 산책 시작/종료 로직
  Future<void> _toggleWalking() async {
    if (_isWalking) {
      // 산책 종료 로직
      await _positionStream?.cancel();
      setState(() {
        _isWalking = false;
      });
      print("🏁 산책 종료. 총 이동 데이터 포인트: ${_pathPoints.length}");
    } else {
      // 산책 시작 전 권한 체크
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      setState(() {
        _isWalking = true;
        _pathPoints.clear(); // 새 산책 시작 시 이전 경로 초기화
      });

      // 실시간 위치 추적 시작 (5m 이동 시마다 업데이트)
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, 
        ),
      ).listen((Position position) {
        _updatePath(position);
      });
    }
  }

  // 3. 지도 위에 실시간으로 경로 그리기
  void _updatePath(Position position) {
    final newPoint = NLatLng(position.latitude, position.longitude);
    
    setState(() {
      _pathPoints.add(newPoint);
    });

    // 지도 위에 폴리라인(산책로) 오버레이 추가
    if (_pathPoints.length >= 2) {
      final polyline = NPolylineOverlay(
        id: "walking_route",
        coords: _pathPoints,
        color: Colors.blueAccent,
        width: 5,
      );
      _mapController?.addOverlay(polyline);
    }

    // 카메라를 현재 위치로 부드럽게 이동
    _mapController?.updateCamera(NCameraUpdate.withParams(
      target: newPoint,
      bearing: position.heading, // 진행 방향으로 지도 회전 (Head-up 모드)
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("반려견 산책 지도"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 💡 네이버 지도 본체
          NaverMap(
            options: const NaverMapViewOptions(
              locationButtonEnable: true, // 내 위치 찾기 버튼 활성화
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5665, 126.9780), // 초기값 서울시청
                zoom: 15,
              ),
            ),
            onMapReady: (controller) => _mapController = controller,
          ),

          // 💡 하단 산책 제어 카드
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isWalking ? "🏃 열심히 산책 중!" : "🏠 산책 나갈 준비 되셨나요?",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _toggleWalking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isWalking ? Colors.redAccent : Colors.green,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _isWalking ? "산책 종료" : "산책 시작하기",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}