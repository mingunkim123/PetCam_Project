import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:permission_handler/permission_handler.dart'; // 권한 요청 패키지

import '../utils/constants.dart';
import '../providers/photo_provider.dart';
import '../services/ble_service.dart';
import '../services/ai_service.dart';
import '../widgets/image_preview_list.dart';
import '../widgets/control_panel.dart';
import '../widgets/main_drawer.dart';
import '../widgets/ai_comparison_sheet.dart';
import '../widgets/empty_photo_state.dart';
import '../widgets/connection_status_badge.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BleService _bleService = BleService();
  final AiService _aiService = AiService();

  bool _isConnected = false;
  bool _isProcessing = false;
  int? _confirmedIndex;

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // 1. 권한 요청 먼저 실행

    // BLE 연결 상태 감시
    _bleService.onConnectionChanged = (connected) {
      if (mounted) setState(() => _isConnected = connected);
    };

    // BLE로 사진 수신 시 Provider에 저장
    _bleService.onImageReceived = (Uint8List img) {
      if (mounted) {
        context.read<PhotoProvider>().addPhoto(img);
      }
    };

    // 📸 미리보기 수신 시 다이얼로그 표시
    _bleService.onPreviewReceived = (Uint8List img) {
      if (mounted) {
        _showPreviewDialog(img);
      }
    };
  }

  // 권한 요청 함수
  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses.values.any((status) => status.isDenied)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ 권한이 거부되어 기기를 찾을 수 없습니다.")),
        );
      }
    }
  }

  // AI 업스케일링 처리 로직
  Future<void> _handleAiUpscale(String photoId, Uint8List original) async {
    setState(() => _isProcessing = true);

    try {
      final upscaled = await _aiService.upscaleImage(original);

      if (upscaled != null && mounted) {
        context.read<PhotoProvider>().updateUpscaledPhoto(photoId, upscaled);
        AiComparisonSheet.show(context, original, upscaled);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ AI 서버 응답이 없습니다. 서버 상태를 확인하세요.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ 에러 발생: $e")));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoProvider = context.watch<PhotoProvider>();
    final photos = photoProvider.photos;

    return Scaffold(
      backgroundColor: kBgColor,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          // 1. Background Gradient (Subtle)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kSecondaryColor.withOpacity(0.05), kBgColor],
              ),
            ),
          ),

          // 2. Custom App Bar & Content
          SafeArea(
            child: Column(
              children: [
                // Custom Header
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (context) => IconButton(
                          icon: const Icon(
                            Icons.menu_rounded,
                            size: 28,
                            color: kPrimaryColor,
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                      const Text(
                        "PetCam AI",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: kPrimaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      ConnectionStatusBadge(
                        isConnected: _isConnected,
                        onTap: () => _bleService.connectToDevice(),
                      ),
                    ],
                  ),
                ),

                if (_isProcessing)
                  const LinearProgressIndicator(
                    color: kSecondaryColor,
                    backgroundColor: Colors.transparent,
                  ),

                // Main Content
                Expanded(
                  child: photos.isEmpty
                      ? const EmptyPhotoState()
                      : ImagePreviewList(
                          photos: photos,
                          recommendedIndex: _confirmedIndex,
                          confirmedIndex: _confirmedIndex,
                          onSelect: (idx) =>
                              setState(() => _confirmedIndex = idx),
                          onAiUpscale: (idx) => _handleAiUpscale(
                            photos[idx].id,
                            photos[idx].originalBytes,
                          ),
                        ),
                ),

                // Bottom Control Panel (Unified Dock)
                ControlPanel(
                  isConnected: _isConnected,
                  isProcessing: _isProcessing,
                  onSnap: () => _bleService.sendSnapCommand(),
                  onBurst: _handleBurstCapture,
                  onWalk: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapScreen(),
                      ),
                    );
                  },
                  // 미리보기 버튼 추가
                  onPreview: () {
                    if (!_isConnected) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("⚠️ 기기가 연결되지 않았습니다.")),
                      );
                      return;
                    }
                    // 중복 요청 방지
                    if (_isProcessing) return;

                    setState(() {
                      _isProcessing = true; // 로딩 시작
                    });

                    _bleService.sendPreviewCommand();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("📸 미리보기 요청 중...")),
                    );

                    // ⏳ 5초 타임아웃 (응답 없으면 로딩 해제)
                    Future.delayed(const Duration(seconds: 5), () {
                      if (mounted && _isProcessing) {
                        setState(() {
                          _isProcessing = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("❌ 응답이 없습니다. (카메라 점검 필요)"),
                          ),
                        );
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Burst 모드 핸들러 (시각적 피드백 추가)
  void _handleBurstCapture() {
    if (!_isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ 기기가 연결되지 않았습니다.")));
      return;
    }

    // 1. 명령 전송
    _bleService.sendBurstCommand();

    // 2. 진행 상태 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BurstProgressDialog(),
    );
  }

  void _showPreviewDialog(Uint8List imageBytes) {
    setState(() {
      _isProcessing = false; // 로딩 끝
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("📸 Camera Preview"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.memory(imageBytes, fit: BoxFit.contain),
            const SizedBox(height: 10),
            const Text("This is a low-res preview from the camera."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}

// Burst 진행 상태 표시 다이얼로그
class BurstProgressDialog extends StatefulWidget {
  const BurstProgressDialog({super.key});

  @override
  State<BurstProgressDialog> createState() => _BurstProgressDialogState();
}

class _BurstProgressDialogState extends State<BurstProgressDialog> {
  String _status = "📸 연속 촬영 시작...";

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() async {
    // 1. 촬영 시뮬레이션 (0.5s 간격 * 3장)
    for (int i = 1; i <= 3; i++) {
      if (!mounted) return;
      setState(() {
        _status = "📸 연속 촬영 중... ($i/3)";
      });
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // 2. 베스트 컷 분석
    if (!mounted) return;
    setState(() {
      _status = "🧠 AI 베스트 컷 분석 중...";
    });
    await Future.delayed(const Duration(seconds: 2));

    // 3. 완료
    if (!mounted) return;
    setState(() {
      _status = "✨ 업스케일링 완료!\n(Wi-Fi 동기화 대기 중)";
    });
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          const CircularProgressIndicator(color: kSecondaryColor),
          const SizedBox(height: 20),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
