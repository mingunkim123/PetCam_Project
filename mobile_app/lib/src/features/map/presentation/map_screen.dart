import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/constants.dart';
import '../../gallery/data/gallery_repository.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // 1. 상태 변수 및 컨트롤러
  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  List<NLatLng> _pathPoints = []; // 산책 경로 좌표 리스트
  bool _isWalking = false; // 산책 중 상태 플래그
  bool _showHappyCourse = true; // 행복 산책 코스 표시 여부

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

    final repository = ref.read(galleryRepositoryProvider);
    final photos = await repository.fetchPhotos();
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
          icon: const NOverlayImage.fromAssetImage("assets/marker_icon.png"),
        );

        // 마커 클릭 리스너
        marker.setOnTapListener((overlay) {
          _showPhotoDialog(photo);
        });

        _mapController!.addOverlay(marker);
      }
    }

    // 💡 행복 산책 코스 (사진들을 연결한 경로) 그리기
    if (photos.isNotEmpty && _showHappyCourse) {
      List<NLatLng> photoPoints = [];
      for (var photo in photos) {
        if (photo['latitude'] != null && photo['longitude'] != null) {
          double lat = photo['latitude'];
          double lng = photo['longitude'];
          if (lat != 0.0 && lng != 0.0) {
            photoPoints.add(NLatLng(lat, lng));
          }
        }
      }

      if (photoPoints.length >= 2) {
        final happyRoute = NPolylineOverlay(
          id: "happy_walk_course",
          coords: photoPoints,
          color: Colors.pinkAccent.withOpacity(0.7),
          width: 8,
        );
        _mapController?.addOverlay(happyRoute);
      }
    }
  }

  void _toggleHappyCourse() {
    setState(() {
      _showHappyCourse = !_showHappyCourse;
    });
    if (_showHappyCourse) {
      _loadPhotoMarkers(); // 다시 로드 (오버레이 추가)
    } else {
      _mapController?.deleteOverlay(
        const NOverlayInfo(
          type: NOverlayType.polylineOverlay,
          id: "happy_walk_course",
        ),
      );
    }
  }

  // 🖼️ 사진 보기 다이얼로그
  void _showPhotoDialog(dynamic photo) {
    final repository = ref.read(galleryRepositoryProvider);
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
                repository.getPhotoUrl(photo['id']),
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
        actions: [
          IconButton(
            icon: Icon(
              _showHappyCourse ? Icons.favorite : Icons.favorite_border,
              color: Colors.pinkAccent,
            ),
            onPressed: _toggleHappyCourse,
            tooltip: "행복 산책 코스 보기",
          ),
        ],
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
                boxShadow: [kHardShadow],
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
