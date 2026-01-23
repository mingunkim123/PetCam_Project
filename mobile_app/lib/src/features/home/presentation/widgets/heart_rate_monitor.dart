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
      padding: const EdgeInsets.all(kPaddingM),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kBorderRadiusL),
        boxShadow: [kSoftShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Heart Rate",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kSuccessColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Live",
                  style: TextStyle(
                    color: kSuccessColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          heartRateAsync.when(
            data: (data) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${data.bpm}",
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: kTextPrimary,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      "BPM",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _buildEmotionBadge(data.emotion),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionBadge(String emotion) {
    // ... (rest of the code)
    Color color;
    IconData icon;

    switch (emotion) {
      case 'Happy':
        color = Colors.orange;
        icon = Icons.sentiment_very_satisfied_rounded;
        break;
      case 'Relaxed':
        color = Colors.blue;
        icon = Icons.sentiment_satisfied_rounded;
        break;
      case 'Excited':
        color = Colors.purple;
        icon = Icons.bolt_rounded;
        break;
      default:
        color = kTextSecondary;
        icon = Icons.sentiment_neutral_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            emotion,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
