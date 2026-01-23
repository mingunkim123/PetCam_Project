import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/widgets/ad_banner.dart';
import '../../../core/widgets/connection_status_badge.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../core/widgets/section_header.dart';
import '../../../services/ai_service.dart';
import '../../../services/ble_service.dart';
import 'widgets/control_panel.dart';
import 'widgets/featured_pet_photo.dart';
import 'widgets/heart_rate_monitor.dart';
import 'widgets/pet_profile_card.dart';
import 'widgets/summary_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Services
  final BleService _bleService = BleService();
  final AiService _aiService = AiService();

  @override
  Widget build(BuildContext context) {
    // final petProfileAsync = ref.watch(petControllerProvider); // Unused for now
    // final photos = ref.watch(localPhotoControllerProvider); // Unused for now

    return Scaffold(
      backgroundColor: kAppBackground,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 1. App Bar with Pet Profile
              SliverAppBar(
                expandedHeight: 220,
                floating: false,
                pinned: true,
                backgroundColor: kAppBackground,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: const PetProfileCard(),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: ConnectionStatusBadge(
                      isConnected: true, // TODO: Get from provider
                      onTap: () => _bleService.connectToDevice(),
                    ),
                  ),
                ],
              ),

              // 2. Featured Pet Photo (Moved Up)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      const SectionHeader(title: "My Pet"),
                      const FeaturedPetPhoto(),
                    ],
                  ),
                ),
              ),

              // 3. Summary Grid (Bento Style)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1, // Adjusted for taller cards
                  children: const [
                    SummaryCard(
                      title: "Walk Distance",
                      value: "2.4 km",
                      icon: Icons.directions_walk_rounded,
                      color: Colors.green,
                    ),
                    SummaryCard(
                      title: "Active Time",
                      value: "45 min",
                      icon: Icons.timer_rounded,
                      color: Colors.orange,
                    ),
                    SummaryCard(
                      title: "Calories",
                      value: "120 kcal",
                      icon: Icons.local_fire_department_rounded,
                      color: Colors.redAccent,
                    ),
                  ],
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 4. Heart Rate Monitor
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const HeartRateMonitor(),
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
                      context.push('/gallery');
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
                          color: kSecondaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Space for Control Panel and Ad Banner
              const SliverToBoxAdapter(child: SizedBox(height: 200)),
            ],
          ),

          // 5. Floating Control Panel
          Positioned(
            bottom: 90, // AdBanner height (60) + padding (30)
            left: 0,
            right: 0,
            child: const ControlPanel(),
          ),

          // 6. Ad Banner
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(top: false, child: const AdBanner()),
          ),
        ],
      ),
    );
  }

  void _showPreviewDialog(Uint8List imageBytes) {
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
