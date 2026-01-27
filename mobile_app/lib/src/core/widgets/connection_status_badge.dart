import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/constants.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final bool isConnected;
  final VoidCallback? onTap;

  const ConnectionStatusBadge({
    super.key,
    required this.isConnected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? kSuccessColor : kTextTertiary;
    final text = isConnected ? '연결됨' : '연결 안됨';
    final icon = isConnected
        ? Icons.bluetooth_connected_rounded
        : Icons.bluetooth_disabled_rounded;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: kDurationMedium,
        padding: const EdgeInsets.symmetric(
          horizontal: kSpaceM,
          vertical: kSpaceS,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(kRadiusFull),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated dot
            AnimatedContainer(
              duration: kDurationMedium,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: isConnected
                    ? [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(width: kSpaceS),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
