import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ControlPanel extends StatelessWidget {
  final bool isConnected;
  final bool isProcessing;
  final VoidCallback onSnap;
  final VoidCallback onBurst;
  final VoidCallback onWalk;
  final VoidCallback onPreview; // Added Preview callback

  const ControlPanel({
    super.key,
    required this.isConnected,
    required this.isProcessing,
    required this.onSnap,
    required this.onBurst,
    required this.onWalk,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 30),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Action: Snap
          _buildSideBtn(
            onSnap,
            Icons.camera_alt_rounded,
            "Snap",
            isConnected && !isProcessing,
          ),

          // Preview Action (New)
          _buildSideBtn(
            onPreview,
            Icons.visibility_rounded,
            "View",
            isConnected && !isProcessing,
          ),

          // Center Action: Walk (Primary)
          _buildCenterBtn(),

          // Right Action: Burst
          _buildSideBtn(
            onBurst,
            Icons.burst_mode_rounded,
            "Burst",
            isConnected && !isProcessing,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterBtn() {
    return Container(
      height: 72,
      width: 72,
      decoration: BoxDecoration(
        gradient: kPrimaryGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: kSecondaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onWalk,
          borderRadius: BorderRadius.circular(36),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.directions_walk_rounded,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 2),
              Text(
                "GO",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideBtn(
    VoidCallback? action,
    IconData icon,
    String label,
    bool enabled,
  ) {
    final color = enabled ? kPrimaryColor : Colors.grey[300];

    return InkWell(
      onTap: enabled ? action : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
