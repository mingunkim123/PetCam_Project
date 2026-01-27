import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/constants.dart';
import '../../gallery/data/gallery_repository.dart';
import '../../../services/heart_rate_service.dart';
import 'package:uuid/uuid.dart';
import '../data/walk_repository.dart';
import '../domain/walk_point.dart';
import '../domain/walk_session.dart';
import 'walk_history_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  NaverMapController? _mapController;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<HeartRateData>? _heartRateStream;

  final List<NLatLng> _pathPoints = [];
  final List<WalkPoint> _walkData = [];

  bool _isWalking = false;
  bool _showHappyCourse = true;

  int _currentBpm = 0;
  DateTime? _startTime;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _heartRateStream?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleWalking() async {
    HapticFeedback.mediumImpact();

    if (_isWalking) {
      await _stopWalking();
    } else {
      await _startWalking();
    }
  }

  Future<void> _startWalking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showPermissionDeniedSnackBar();
        return;
      }
    }

    setState(() {
      _isWalking = true;
      _pathPoints.clear();
      _walkData.clear();
      _startTime = DateTime.now();
    });

    _animationController.repeat(reverse: true);

    await ref.read(walkRepositoryProvider).saveWalkData([], [], true);

    final heartRateService = ref.read(heartRateServiceProvider);
    _heartRateStream = heartRateService.heartRateStream.listen((data) {
      setState(() => _currentBpm = data.bpm);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _updatePath(position);
    });
  }

  Future<void> _stopWalking() async {
    await _positionStream?.cancel();
    await _heartRateStream?.cancel();
    _animationController.stop();
    _animationController.reset();

    setState(() => _isWalking = false);

    _analyzeBestSpot();

    if (_pathPoints.isNotEmpty) {
      final session = WalkSession(
        id: const Uuid().v4(),
        startTime: _startTime ?? DateTime.now(),
        endTime: DateTime.now(),
        pathPoints: List.from(_pathPoints),
        walkData: List.from(_walkData),
        maxBpm: _walkData.isEmpty
            ? 0
            : _walkData.map((e) => e.bpm).reduce(max),
      );
      await ref.read(walkRepositoryProvider).saveWalkSession(session);
    }

    await ref.read(walkRepositoryProvider).clearWalkData();
    _startTime = null;
  }

  void _updatePath(Position position) {
    final newPoint = NLatLng(position.latitude, position.longitude);

    setState(() {
      _pathPoints.add(newPoint);
      _walkData.add(
        WalkPoint(
          location: newPoint,
          bpm: _currentBpm,
          timestamp: DateTime.now(),
        ),
      );
    });

    ref
        .read(walkRepositoryProvider)
        .saveWalkData(_walkData, _pathPoints, _isWalking);

    if (_pathPoints.length >= 2) {
      final polyline = NPolylineOverlay(
        id: "walking_route",
        coords: _pathPoints,
        color: kSecondaryColor,
        width: 6,
      );
      _mapController?.addOverlay(polyline);
    }

    _mapController?.updateCamera(
      NCameraUpdate.withParams(target: newPoint, bearing: position.heading),
    );
  }

  void _analyzeBestSpot() {
    if (_walkData.isEmpty) return;

    WalkPoint bestPoint = _walkData.reduce(
      (curr, next) => curr.bpm > next.bpm ? curr : next,
    );

    final marker = NMarker(
      id: "best_spot_marker",
      position: bestPoint.location,
      caption: NOverlayCaption(text: "최고의 순간!"),
      subCaption: NOverlayCaption(text: "${bestPoint.bpm} BPM"),
    );
    _mapController?.addOverlay(marker);

    _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(target: bestPoint.location, zoom: 17),
    );

    if (mounted) {
      _showBestSpotDialog(bestPoint);
    }
  }

  void _showBestSpotDialog(WalkPoint bestPoint) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(kSpaceXXL),
          decoration: kCardDecoration(borderRadius: kRadiusXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(kSpaceL),
                decoration: BoxDecoration(
                  gradient: kSunsetGradient,
                  shape: BoxShape.circle,
                  boxShadow: [kColoredShadow(kAccentOrange, opacity: 0.4)],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: kSpaceXXL),
              Text(
                "오늘의 베스트 스팟!",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: kSpaceM),
              Text(
                "이곳에서 반려동물이 가장 신났어요",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kSpaceXL),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceXXL,
                  vertical: kSpaceL,
                ),
                decoration: BoxDecoration(
                  color: kAccentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kRadiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: kAccentColor,
                      size: 24,
                    ),
                    const SizedBox(width: kSpaceS),
                    Text(
                      "${bestPoint.bpm} BPM",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: kAccentColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: kSpaceXXL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("확인"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadPhotoMarkers() async {
    if (_mapController == null) return;

    final repository = ref.read(galleryRepositoryProvider);
    final photos = await repository.fetchPhotos();

    for (var photo in photos) {
      if (photo['latitude'] != null && photo['longitude'] != null) {
        double lat = photo['latitude'];
        double lng = photo['longitude'];
        if (lat == 0.0 && lng == 0.0) continue;

        final marker = NMarker(
          id: photo['id'],
          position: NLatLng(lat, lng),
          icon: const NOverlayImage.fromAssetImage("assets/marker_icon.png"),
        );

        marker.setOnTapListener((overlay) {
          _showPhotoDialog(photo);
        });

        _mapController!.addOverlay(marker);
      }
    }

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
          color: kAccentPink.withOpacity(0.7),
          width: 8,
        );
        _mapController?.addOverlay(happyRoute);
      }
    }
  }

  void _toggleHappyCourse() {
    HapticFeedback.lightImpact();
    setState(() => _showHappyCourse = !_showHappyCourse);

    if (_showHappyCourse) {
      _loadPhotoMarkers();
    } else {
      _mapController?.deleteOverlay(
        const NOverlayInfo(
          type: NOverlayType.polylineOverlay,
          id: "happy_walk_course",
        ),
      );
    }
  }

  Future<void> _loadWalkData() async {
    final repository = ref.read(walkRepositoryProvider);
    final data = await repository.loadWalkData();

    final bool isWalking = data['isWalking'];
    final List<WalkPoint> walkData = data['walkData'];
    final List<NLatLng> pathPoints = data['pathPoints'];

    if (isWalking || pathPoints.isNotEmpty) {
      setState(() {
        _isWalking = isWalking;
        _walkData.addAll(walkData);
        _pathPoints.addAll(pathPoints);
      });

      if (_pathPoints.length >= 2) {
        final polyline = NPolylineOverlay(
          id: "walking_route",
          coords: _pathPoints,
          color: kSecondaryColor,
          width: 6,
        );
        _mapController?.addOverlay(polyline);
      }

      if (_isWalking) {
        _animationController.repeat(reverse: true);
        _resumeWalking();
      }
    }
  }

  Future<void> _resumeWalking() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      return;
    }

    final heartRateService = ref.read(heartRateServiceProvider);
    _heartRateStream = heartRateService.heartRateStream.listen((data) {
      setState(() => _currentBpm = data.bpm);
    });

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _updatePath(position);
    });
  }

  void _showPhotoDialog(dynamic photo) {
    final repository = ref.read(galleryRepositoryProvider);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: kCardDecoration(borderRadius: kRadiusXXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(kRadiusXXL),
                ),
                child: Image.network(
                  repository.getPhotoUrl(photo['id']),
                  fit: BoxFit.cover,
                  height: 300,
                  width: double.infinity,
                  loadingBuilder: (ctx, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 300,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: kSecondaryColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(kSpaceL),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("닫기"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('위치 권한이 필요합니다'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: '설정',
          onPressed: () => Geolocator.openAppSettings(),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double _calculateDistance() {
    if (_pathPoints.length < 2) return 0;
    double total = 0;
    for (int i = 0; i < _pathPoints.length - 1; i++) {
      total += Geolocator.distanceBetween(
        _pathPoints[i].latitude,
        _pathPoints[i].longitude,
        _pathPoints[i + 1].latitude,
        _pathPoints[i + 1].longitude,
      );
    }
    return total / 1000; // km
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Map
          NaverMap(
            options: const NaverMapViewOptions(
              locationButtonEnable: true,
              initialCameraPosition: NCameraPosition(
                target: NLatLng(37.5665, 126.9780),
                zoom: 15,
              ),
            ),
            onMapReady: (controller) {
              _mapController = controller;
              _loadPhotoMarkers();
              _loadWalkData();
            },
          ),

          // Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(kSpaceL),
                child: Row(
                  children: [
                    // Title Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: kSpaceL,
                          vertical: kSpaceM,
                        ),
                        decoration: kGlassDecoration(opacity: 0.9),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(kSpaceS),
                              decoration: BoxDecoration(
                                gradient: _isWalking
                                    ? kAccentGradient
                                    : kPrimaryGradient,
                                borderRadius: BorderRadius.circular(kRadiusS),
                              ),
                              child: Icon(
                                _isWalking
                                    ? Icons.directions_run_rounded
                                    : Icons.map_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: kSpaceM),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isWalking ? '산책 중' : '산책 지도',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  if (_isWalking)
                                    Text(
                                      '${_currentBpm} BPM',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: kAccentColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: kSpaceM),
                    // Action Buttons
                    _buildTopButton(
                      icon: _showHappyCourse
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: kAccentPink,
                      onTap: _toggleHappyCourse,
                    ),
                    const SizedBox(width: kSpaceS),
                    _buildTopButton(
                      icon: Icons.history_rounded,
                      color: kSecondaryColor,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalkHistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 100, // Above bottom nav
            left: kSpaceL,
            right: kSpaceL,
            child: _buildControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(kSpaceM),
        decoration: kGlassDecoration(opacity: 0.9),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildControlPanel() {
    final duration = _startTime != null
        ? DateTime.now().difference(_startTime!)
        : Duration.zero;

    return Container(
      padding: const EdgeInsets.all(kSpaceL),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kRadiusXXL),
        boxShadow: [kShadowL],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stats Row (visible when walking)
          if (_isWalking) ...[
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.timer_rounded,
                    label: '시간',
                    value: _formatDuration(duration),
                    color: kSecondaryColor,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: kTextMuted.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.straighten_rounded,
                    label: '거리',
                    value: '${_calculateDistance().toStringAsFixed(2)} km',
                    color: kAccentGreen,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: kTextMuted.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.favorite_rounded,
                    label: 'BPM',
                    value: '$_currentBpm',
                    color: kAccentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSpaceL),
          ],

          // Main Button
          Row(
            children: [
              if (!_isWalking) ...[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '산책 준비 완료',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: kSpaceXXS),
                      Text(
                        '반려동물과 함께 산책을 시작하세요',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: kSpaceL),
              ],
              Expanded(
                flex: _isWalking ? 1 : 0,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isWalking ? _pulseAnimation.value : 1.0,
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _toggleWalking,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isWalking ? kAccentColor : kSecondaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(kRadiusL),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isWalking
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                size: 24,
                              ),
                              const SizedBox(width: kSpaceS),
                              Text(
                                _isWalking ? '산책 종료' : '시작',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: kSpaceXS),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: kTextTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
