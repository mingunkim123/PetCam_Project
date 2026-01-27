import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/constants.dart';
import '../../../core/widgets/connection_status_badge.dart';
import '../../../core/widgets/main_drawer.dart';
import '../../../services/ai_service.dart';
import '../../../services/ble_service.dart';
import 'widgets/control_panel.dart';
import 'widgets/featured_pet_photo.dart';
import 'widgets/heart_rate_monitor.dart';
import 'widgets/pet_profile_card.dart';
import 'widgets/pet_favorites_card.dart';
import 'widgets/summary_card.dart';
import 'home_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final BleService _bleService = BleService();
  final ScrollController _scrollController = ScrollController();

  late AnimationController _animationController;
  late Animation<double> _headerAnimation;

  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _animationController.forward();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final isScrolled = _scrollController.offset > 80;
    if (isScrolled != _isScrolled) {
      setState(() => _isScrolled = isScrolled);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kAppBackground,
      drawer: const MainDrawer(),
      body: Stack(
        children: [
          // Main Content
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Custom App Bar
              _buildAppBar(),

              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  kSpaceL,
                  kSpaceM,
                  kSpaceL,
                  200, // Bottom padding for control panel + bottom nav
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Pet Profile Card
                    FadeTransition(
                      opacity: _headerAnimation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(_headerAnimation),
                        child: const PetProfileCard(),
                      ),
                    ),

                    const SizedBox(height: kSpaceXXL),

                    // Featured Photo Section
                    _buildSectionHeader(
                      title: '오늘의 순간',
                      subtitle: '탭하여 AI 분석 보기',
                      icon: Icons.auto_awesome_rounded,
                    ),
                    const SizedBox(height: kSpaceM),
                    const FeaturedPetPhoto(),

                    // Favorites Section
                    Consumer(
                      builder: (context, ref, child) {
                        final petProfile =
                            ref.watch(petControllerProvider).asData?.value;
                        if (petProfile == null) return const SizedBox.shrink();
                        return Column(
                          children: [
                            const SizedBox(height: kSpaceL),
                            PetFavoritesCard(profile: petProfile),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: kSpace3XL),

                    // Activity Stats Section
                    _buildSectionHeader(
                      title: '활동 통계',
                      subtitle: '오늘의 활동',
                      icon: Icons.insights_rounded,
                    ),
                    const SizedBox(height: kSpaceM),
                    _buildActivityGrid(),

                    const SizedBox(height: kSpace3XL),

                    // Heart Rate Section
                    _buildSectionHeader(
                      title: '심박수',
                      subtitle: '실시간 모니터링',
                      icon: Icons.favorite_rounded,
                      iconColor: kAccentColor,
                    ),
                    const SizedBox(height: kSpaceM),
                    const HeartRateMonitor(),

                    const SizedBox(height: kSpace3XL),

                    // Quick Actions
                    _buildQuickActions(),
                  ]),
                ),
              ),
            ],
          ),

          // Floating Control Panel
          Positioned(
            bottom: 90, // Above bottom nav
            left: kSpaceXXL,
            right: kSpaceXXL,
            child: const ControlPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 60,
      floating: true,
      pinned: false,
      backgroundColor: _isScrolled
          ? kCardBackground.withOpacity(0.95)
          : Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) => GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Scaffold.of(context).openDrawer();
          },
          child: Container(
            margin: const EdgeInsets.only(left: kSpaceM),
            padding: const EdgeInsets.all(kSpaceS),
            decoration: BoxDecoration(
              color: _isScrolled
                  ? kSurfaceElevated
                  : kCardBackground.withOpacity(0.9),
              borderRadius: BorderRadius.circular(kRadiusM),
              boxShadow: _isScrolled ? null : [kShadowXS],
            ),
            child: const Icon(
              Icons.menu_rounded,
              color: kPrimaryColor,
              size: 22,
            ),
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _isScrolled ? 1.0 : 0.0,
        duration: kDurationMedium,
        child: Text(
          'PetCam',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      flexibleSpace: AnimatedOpacity(
        opacity: _isScrolled ? 0.0 : 1.0,
        duration: kDurationMedium,
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 70, bottom: 16),
          title: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '안녕하세요!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kTextTertiary,
                  fontSize: 10,
                ),
              ),
              Text(
                'PetCam',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: kSpaceM),
          child: ConnectionStatusBadge(
            isConnected: true, // TODO: Get from provider
            onTap: () => _bleService.connectToDevice(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(kSpaceS),
          decoration: BoxDecoration(
            color: (iconColor ?? kSecondaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(kRadiusM),
          ),
          child: Icon(
            icon,
            size: kIconS,
            color: iconColor ?? kSecondaryColor,
          ),
        ),
        const SizedBox(width: kSpaceM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: kTextTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: kSpaceM,
      crossAxisSpacing: kSpaceM,
      childAspectRatio: 1.15,
      children: [
        SummaryCard(
          title: "산책 거리",
          value: "2.4 km",
          icon: Icons.directions_walk_rounded,
          gradient: kSuccessGradient,
        ),
        SummaryCard(
          title: "활동 시간",
          value: "45 min",
          icon: Icons.timer_rounded,
          gradient: kSunsetGradient,
        ),
        SummaryCard(
          title: "소모 칼로리",
          value: "120 kcal",
          icon: Icons.local_fire_department_rounded,
          gradient: kAccentGradient,
        ),
        SummaryCard(
          title: "촬영 횟수",
          value: "12",
          icon: Icons.camera_alt_rounded,
          gradient: kOceanGradient,
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          title: '바로가기',
          subtitle: '자주 사용하는 기능',
          icon: Icons.apps_rounded,
        ),
        const SizedBox(height: kSpaceM),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.photo_library_rounded,
                label: '갤러리',
                color: kAccentPurple,
                onTap: () => context.go('/gallery'),
              ),
            ),
            const SizedBox(width: kSpaceM),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.map_rounded,
                label: '산책 지도',
                color: kAccentGreen,
                onTap: () => context.go('/map'),
              ),
            ),
            const SizedBox(width: kSpaceM),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.storefront_rounded,
                label: '펫 스토어',
                color: kAccentOrange,
                onTap: () => context.go('/store'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showPreviewDialog(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: kCardDecoration(borderRadius: kRadiusXXL),
          padding: const EdgeInsets.all(kSpaceL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(kRadiusL),
                child: Image.memory(imageBytes, fit: BoxFit.contain),
              ),
              const SizedBox(height: kSpaceL),
              Text(
                '카메라 미리보기',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: kSpaceS),
              Text(
                '저해상도 미리보기 이미지입니다',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: kSpaceL),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('닫기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick Action Button Widget
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: kSpaceM,
          vertical: kSpaceL,
        ),
        decoration: kCardDecoration(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(kSpaceM),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(kRadiusM),
              ),
              child: Icon(icon, color: color, size: kIconL),
            ),
            const SizedBox(height: kSpaceS),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// BurstProgressDialog - Improved
class BurstProgressDialog extends StatefulWidget {
  const BurstProgressDialog({super.key});

  @override
  State<BurstProgressDialog> createState() => _BurstProgressDialogState();
}

class _BurstProgressDialogState extends State<BurstProgressDialog> {
  String _status = "연속 촬영 시작...";
  IconData _statusIcon = Icons.camera_alt_rounded;
  Color _statusColor = kSecondaryColor;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  void _startSimulation() async {
    for (int i = 1; i <= 10; i++) {
      if (!mounted) return;
      setState(() {
        _status = "연속 촬영 중... ($i/10)";
        _progress = i / 10;
        _statusIcon = Icons.camera_alt_rounded;
        _statusColor = kSecondaryColor;
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }
    if (!mounted) return;
    setState(() {
      _status = "AI 베스트 컷 분석 중...";
      _statusIcon = Icons.auto_awesome_rounded;
      _statusColor = kAccentPurple;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _status = "업스케일링 완료!";
      _statusIcon = Icons.check_circle_rounded;
      _statusColor = kSuccessColor;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                color: _statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _statusIcon,
                color: _statusColor,
                size: 40,
              ),
            ),
            const SizedBox(height: kSpaceXXL),
            Text(
              _status,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: kSpaceL),
            ClipRRect(
              borderRadius: BorderRadius.circular(kRadiusFull),
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: kSurfaceElevated,
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
