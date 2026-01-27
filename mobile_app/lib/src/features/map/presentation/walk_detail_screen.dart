import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/constants.dart';
import '../domain/walk_session.dart';

class WalkDetailScreen extends StatefulWidget {
  final WalkSession session;

  const WalkDetailScreen({super.key, required this.session});

  @override
  State<WalkDetailScreen> createState() => _WalkDetailScreenState();
}

class _WalkDetailScreenState extends State<WalkDetailScreen> {
  NaverMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final duration = widget.session.duration;
    final dateStr = DateFormat(
      'yyyy.MM.dd HH:mm',
    ).format(widget.session.startTime);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          dateStr,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: kPrimaryColor,
          ),
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.8),
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
          NaverMap(
            options: const NaverMapViewOptions(
              locationButtonEnable: false,
              scrollGesturesEnable: true,
              zoomGesturesEnable: true,
            ),
            onMapReady: (controller) {
              _mapController = controller;
              _drawPath();
            },
          ),
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [kHardShadow],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.timer_outlined,
                        "${duration.inMinutes} min",
                        "Duration",
                      ),
                      _buildStatItem(
                        Icons.favorite_rounded,
                        "${widget.session.maxBpm} BPM",
                        "Max Heart Rate",
                        color: Colors.redAccent,
                      ),
                      _buildStatItem(
                        Icons.route_rounded,
                        "${widget.session.pathPoints.length} pts",
                        "Points",
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label, {
    Color color = kTextPrimary,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: kTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _drawPath() {
    if (widget.session.pathPoints.length < 2) return;

    final polyline = NPolylineOverlay(
      id: "history_route",
      coords: widget.session.pathPoints,
      color: kAccentColor,
      width: 6,
    );
    _mapController?.addOverlay(polyline);

    // 카메라 이동 (경로 전체가 보이도록)
    // 간단하게 첫 번째 점으로 이동 (추후 bounds 계산하여 fitBounds 적용 가능)
    _mapController?.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: widget.session.pathPoints.first,
        zoom: 15,
      ),
    );

    // 시작점과 끝점 마커 표시
    final startMarker = NMarker(
      id: "start_marker",
      position: widget.session.pathPoints.first,
      caption: const NOverlayCaption(text: "Start"),
      iconTintColor: Colors.green,
    );

    final endMarker = NMarker(
      id: "end_marker",
      position: widget.session.pathPoints.last,
      caption: const NOverlayCaption(text: "End"),
      iconTintColor: Colors.redAccent,
    );

    final Set<NAddableOverlay> overlays = {startMarker, endMarker};

    // 🏆 Best Spot 마커 추가
    if (widget.session.walkData.isNotEmpty) {
      final bestPoint = widget.session.walkData.reduce(
        (curr, next) => curr.bpm > next.bpm ? curr : next,
      );

      final bestSpotMarker = NMarker(
        id: "best_spot_marker",
        position: bestPoint.location,
        caption: NOverlayCaption(text: "Best! 😆"),
        subCaption: NOverlayCaption(text: "${bestPoint.bpm} BPM"),
        iconTintColor: Colors.orange,
      );

      bestSpotMarker.setOnTapListener((overlay) {
        _showBestMomentDialog();
      });

      overlays.add(bestSpotMarker);
    }

    _mapController?.addOverlayAll(overlays);
  }

  void _showBestMomentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.asset(
                "assets/images/happy_dog_best_moment.png",
                fit: BoxFit.cover,
                height: 300,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "최고의 순간! 😆",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "이때 아이가 본 세상이에요!",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("닫기"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
