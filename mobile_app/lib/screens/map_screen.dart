import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';
import '../services/ai_service.dart'; // 💡 AiService 추가

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
  final AiService _aiService = AiService(); // 💡 AI 서비스 인스턴스

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
      _positionStream =
          Geolocator.getPositionStream(
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
    _mapController?.updateCamera(
      NCameraUpdate.withParams(
        target: newPoint,
        bearing: position.heading, // 진행 방향으로 지도 회전 (Head-up 모드)
      ),
    );
  }

  // 📸 4. 사진 마커 로드 함수 (추가)
  Future<void> _loadPhotoMarkers() async {
    if (_mapController == null) return;

    final photos = await _aiService.fetchPhotos();
    print("📍 지도에 표시할 사진 수: ${photos.length}");

    for (var photo in photos) {
      // lat, lng가 있는지 확인 (서버에서 null일 수 있음)
      if (photo['latitude'] != null && photo['longitude'] != null) {
        double lat = photo['latitude'];
        double lng = photo['longitude'];

        // 0.0, 0.0은 유효하지 않은 좌표로 간주
        if (lat == 0.0 && lng == 0.0) continue;

        final marker = NMarker(
          id: photo['id'],
          position: NLatLng(lat, lng),
          icon: const NOverlayImage.fromAssetImage(
            "assets/marker_icon.png",
          ), // 커스텀 아이콘 없으면 기본값 사용됨 (null 처리 필요)
          // 기본 마커 사용 시 icon 설정 생략 가능. 파란 점을 원하셨으므로 기본 마커 색상 변경 시도.
          // Naver Map SDK 기본 마커는 색상 변경이 제한적일 수 있음.
          // 여기서는 기본 핀을 사용하고, 캡션으로 표시.
        );

        // 마커 클릭 리스너
        marker.setOnTapListener((overlay) {
          _showPhotoDialog(photo);
        });

        _mapController!.addOverlay(marker);
      }
    }
  }

  // 🖼️ 사진 보기 다이얼로그
  void _showPhotoDialog(dynamic photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _aiService.getPhotoUrl(photo['id']),
                fit: BoxFit.cover,
                height: 300,
                width: double.infinity,
                loadingBuilder: (ctx, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("닫기"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Walking Map",
          style: TextStyle(fontWeight: FontWeight.w700, color: kPrimaryColor),
        ),
        backgroundColor: Colors.white.withOpacity(0.8),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: kPrimaryColor,
          ),
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
            onMapReady: (controller) {
              _mapController = controller;
              _loadPhotoMarkers(); // 📍 지도 준비되면 마커 로드
            },
          ),

          // 💡 하단 산책 제어 카드 (Floating Glass)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [kStrongShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isWalking
                            ? Icons.directions_run_rounded
                            : Icons.pets_rounded,
                        color: _isWalking ? kAccentColor : kSecondaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isWalking ? "Tracking Walk..." : "Ready to Walk?",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _toggleWalking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isWalking
                            ? kAccentColor
                            : kSecondaryColor,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor:
                            (_isWalking ? kAccentColor : kSecondaryColor)
                                .withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        _isWalking ? "Stop Walking" : "Start Walking",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  if (_isWalking)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        "Points: ${_pathPoints.length}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
