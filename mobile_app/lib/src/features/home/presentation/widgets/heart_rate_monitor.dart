import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../services/heart_rate_service.dart';

class HeartRateMonitor extends ConsumerWidget {
  const HeartRateMonitor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final heartRateAsync = ref.watch(heartRateStreamProvider);

    return Container(
      padding: const EdgeInsets.all(kSpaceL),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kRadiusXXL),
        boxShadow: [kShadowS, kShadowXS],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Animated heart icon
                  _AnimatedHeartIcon(),
                  const SizedBox(width: kSpaceM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "심박수",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        "실시간 모니터링",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: kTextTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Live Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: kSpaceM,
                  vertical: kSpaceXS,
                ),
                decoration: BoxDecoration(
                  color: kSuccessColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(kRadiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: kSuccessColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: kSuccessColor.withOpacity(0.4),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: kSpaceXS),
                    Text(
                      "LIVE",
                      style: TextStyle(
                        color: kSuccessColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: kSpaceXL),

          // Content
          heartRateAsync.when(
            data: (data) => _buildHeartRateContent(context, data),
            loading: () => _buildLoadingState(),
            error: (err, stack) => _buildErrorState(context, err),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateContent(BuildContext context, HeartRateData data) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // BPM Value
            TweenAnimationBuilder<int>(
              duration: kDurationMedium,
              tween: IntTween(begin: 0, end: data.bpm),
              builder: (context, value, child) {
                return Text(
                  "$value",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: kTextPrimary,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                );
              },
            ),
            const SizedBox(width: kSpaceS),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                "BPM",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: kTextTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            _buildEmotionBadge(data.emotion),
          ],
        ),

        const SizedBox(height: kSpaceL),

        // Heart Rate Graph (Simplified visual)
        _buildSimpleGraph(data.bpm),
      ],
    );
  }

  Widget _buildSimpleGraph(int bpm) {
    // Normalize BPM to a percentage (assuming range 60-180)
    final normalized = ((bpm - 60) / 120).clamp(0.0, 1.0);

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: kSurfaceElevated,
        borderRadius: BorderRadius.circular(kRadiusFull),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          Color barColor;
          if (normalized < 0.3) {
            barColor = kAccentGreen;
          } else if (normalized < 0.6) {
            barColor = kAccentOrange;
          } else {
            barColor = kAccentColor;
          }

          return AnimatedContainer(
            duration: kDurationMedium,
            width: constraints.maxWidth * (0.2 + normalized * 0.8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [barColor, barColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(kRadiusFull),
              boxShadow: [kColoredShadow(barColor, opacity: 0.3)],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmotionBadge(String emotion) {
    Color color;
    IconData icon;
    String label;

    switch (emotion) {
      case 'Happy':
        color = kAccentOrange;
        icon = Icons.sentiment_very_satisfied_rounded;
        label = '기쁨';
        break;
      case 'Relaxed':
        color = kAccentCyan;
        icon = Icons.sentiment_satisfied_rounded;
        label = '편안함';
        break;
      case 'Excited':
        color = kAccentPurple;
        icon = Icons.bolt_rounded;
        label = '신남';
        break;
      default:
        color = kTextSecondary;
        icon = Icons.sentiment_neutral_rounded;
        label = '보통';
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: kSpaceM,
        vertical: kSpaceS,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kRadiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: kSpaceXS),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(kSpaceXXL),
        child: CircularProgressIndicator(color: kSecondaryColor),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object err) {
    return Container(
      padding: const EdgeInsets.all(kSpaceL),
      decoration: BoxDecoration(
        color: kErrorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kRadiusM),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kErrorColor),
          const SizedBox(width: kSpaceM),
          Expanded(
            child: Text(
              '연결 오류',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kErrorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated Heart Icon
class _AnimatedHeartIcon extends StatefulWidget {
  @override
  State<_AnimatedHeartIcon> createState() => _AnimatedHeartIconState();
}

class _AnimatedHeartIconState extends State<_AnimatedHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(kSpaceM),
      decoration: BoxDecoration(
        gradient: kAccentGradient,
        borderRadius: BorderRadius.circular(kRadiusM),
        boxShadow: [kColoredShadow(kAccentColor, opacity: 0.3)],
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.scale(
            scale: _animation.value,
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 20,
            ),
          );
        },
      ),
    );
  }
}
