import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../services/ble_service.dart';

class ControlPanel extends ConsumerWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleService = BleService();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 60),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSideBtn(
            () => bleService.sendPreviewCommand(),
            Icons.visibility_rounded,
            true,
          ),
          // Center Snap Button
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              gradient: kPrimaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: kSecondaryColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => bleService.sendSnapCommand(),
                borderRadius: BorderRadius.circular(28),
                child: const Icon(
                  Icons.camera_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
          _buildSideBtn(
            () => bleService.sendBurstCommand(),
            Icons.burst_mode_rounded,
            true,
          ),
        ],
      ),
    );
  }

  Widget _buildSideBtn(VoidCallback? action, IconData icon, bool enabled) {
    final color = enabled ? kTextSecondary : kTextTertiary;

    return IconButton(
      onPressed: enabled ? action : null,
      icon: Icon(icon, color: color, size: 24),
      style: IconButton.styleFrom(
        backgroundColor: Colors.transparent,
        highlightColor: kPrimaryColor.withValues(alpha: 0.1),
      ),
    );
  }
}
