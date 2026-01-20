import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/constants.dart';
import '../providers/riverpod_providers.dart';
import '../services/ble_service.dart';
import '../services/ai_service.dart';

import '../widgets/control_panel.dart';
import '../widgets/main_drawer.dart';
import '../widgets/ai_comparison_sheet.dart';

import '../widgets/connection_status_badge.dart';
import '../widgets/summary_card.dart';
import '../widgets/section_header.dart';
import '../widgets/pet_profile_card.dart';
import '../widgets/featured_pet_photo.dart';
import 'map_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final BleService _bleService = BleService();
  final AiService _aiService = AiService();

  bool _isConnected = false;
  bool _isProcessing = false;
  int? _confirmedIndex;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _bleService.onConnectionChanged = (connected) {
      if (mounted) setState(() => _isConnected = connected);
    };
    _bleService.onImageReceived = (Uint8List img) {
      if (mounted) ref.read(photoProvider.notifier).addPhoto(img);
    };
    _bleService.onPreviewReceived = (Uint8List img) {
      if (mounted) _showPreviewDialog(img);
    };
  }

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

  Future<void> _handleAiUpscale(String photoId, Uint8List original) async {
    setState(() => _isProcessing = true);
    try {
      final upscaled = await _aiService.upscaleImage(original);
      if (upscaled != null && mounted) {
        ref.read(photoProvider.notifier).updateUpscaledPhoto(photoId, upscaled);
        AiComparisonSheet.show(context, original, upscaled);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ AI 서버 응답이 없습니다.")));
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
    final photos = ref.watch(photoProvider);

    return Scaffold(
      backgroundColor: kAppBackground,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. Large Header with Pet Profile
              SliverAppBar(
                expandedHeight: 180.0, // Increased height for profile card
                floating: false,
                pinned: true,
                backgroundColor: kAppBackground,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: const PetProfileCard(),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(
                      right: 20,
                      bottom: 100,
                    ), // Adjust position
                    child: ConnectionStatusBadge(
                      isConnected: _isConnected,
                      onTap: () => _bleService.connectToDevice(),
                    ),
                  ),
                ],
              ),

              // 2. Summary Grid (Bento Style)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    SummaryCard(
                      title: "Photos",
                      value: "${photos.length}",
                      unit: "shots",
                      icon: Icons.photo_library_rounded,
                      iconColor: kSecondaryColor,
                      onTap: () => Navigator.pushNamed(context, '/gallery'),
                    ),
                    SummaryCard(
                      title: "Status",
                      value: _isConnected ? "On" : "Off",
                      unit: "line",
                      icon: _isConnected
                          ? Icons.bluetooth_connected
                          : Icons.bluetooth_disabled,
                      iconColor: _isConnected ? kSuccessColor : kTextSecondary,
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 3. Featured Pet Photo (Replaces Recent Shots)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    children: [
                      const SectionHeader(title: "My Pet"),
                      const FeaturedPetPhoto(),
                    ],
                  ),
                ),
              ),

              // 4. Gallery Link (New)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/gallery');
                    },
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text("View Recent Shots in Gallery"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kCardBackground,
                      foregroundColor: kPrimaryColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(kBorderRadiusM),
                        side: BorderSide(
                          color: kSecondaryColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Space for Control Panel
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),

          // 5. Floating Control Panel
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: ControlPanel(
              isConnected: _isConnected,
              isProcessing: _isProcessing,
              onSnap: () => _bleService.sendSnapCommand(),
              onBurst: _handleBurstCapture,
              onWalk: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapScreen()),
              ),
              onPreview: _handlePreview,
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: kSecondaryColor),
              ),
            ),
        ],
      ),
    );
  }

  void _handlePreview() {
    if (!_isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ 기기가 연결되지 않았습니다.")));
      return;
    }
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    _bleService.sendPreviewCommand();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isProcessing) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("❌ 응답이 없습니다.")));
      }
    });
  }

  void _handleBurstCapture() {
    if (!_isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ 기기가 연결되지 않았습니다.")));
      return;
    }
    _bleService.sendBurstCommand();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const BurstProgressDialog(),
    );
  }

  void _showPreviewDialog(Uint8List imageBytes) {
    setState(() => _isProcessing = false);
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

// BurstProgressDialog remains the same...
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
    for (int i = 1; i <= 10; i++) {
      if (!mounted) return;
      setState(() => _status = "📸 연속 촬영 중... ($i/10)");
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    setState(() => _status = "🧠 AI 베스트 컷 분석 중...");
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _status = "✨ 업스케일링 완료!\n(Wi-Fi 동기화 대기 중)");
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop();
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
