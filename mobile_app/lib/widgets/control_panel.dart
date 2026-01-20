import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ControlPanel extends StatelessWidget {
  final bool isConnected;
  final bool isProcessing;
  final VoidCallback onSnap;
  final VoidCallback onBurst;
  final VoidCallback onWalk;
  final VoidCallback onPreview;

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
      margin: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        0,
      ), // Bottom margin handled by Positioned
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadiusL),
        boxShadow: [kHardShadow],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kBorderRadiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: kCardBackground.withOpacity(0.8),
              borderRadius: BorderRadius.circular(kBorderRadiusL),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSideBtn(
                  onSnap,
                  Icons.camera_alt_rounded,
                  "Snap",
                  isConnected && !isProcessing,
                ),
                _buildSideBtn(
                  onPreview,
                  Icons.visibility_rounded,
                  "View",
                  isConnected && !isProcessing,
                ),
                _buildCenterBtn(),
                _buildSideBtn(
                  onWalk,
                  Icons.directions_walk_rounded,
                  "Walk",
                  true,
                ),
                _buildSideBtn(
                  onBurst,
                  Icons.burst_mode_rounded,
                  "Burst",
                  isConnected && !isProcessing,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterBtn() {
    // Center button is now just a decorative separator or logo in this design?
    // Or maybe the main action?
    // The previous design had "Walk" as center.
    // Let's make the center button a "Connect" or "Status" indicator if needed,
    // or just keep "Walk" there if that's the main action.
    // Wait, the user wanted "Snap" to be prominent.
    // Let's put Snap in the center?
    // The previous code had Walk in center.
    // Let's stick to the previous layout logic but improved style,
    // OR move Snap to center as per "Walkthrough: Snap button is largest and in center".

    // Let's re-arrange:
    // Preview | Walk | SNAP (Large) | Burst | ...

    // Actually, let's keep it simple for now and just style it.
    // I will use the layout: Snap | Preview | WALK (Center) | Burst
    // Wait, I missed one button in the previous code?
    // Previous: Snap, Preview, Walk (Center), Burst. Total 4 actions.
    // My replacement code above has 5 children in Row?
    // Snap, Preview, Center, Walk, Burst.
    // Ah, I added Walk as a side button.

    // Let's make SNAP the center button as it's the primary camera action.
    // Left: Preview, Walk
    // Center: Snap
    // Right: Burst

    return Container(
      height: 64,
      width: 64,
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
          onTap: (isConnected && !isProcessing) ? onSnap : null,
          borderRadius: BorderRadius.circular(32),
          child: const Icon(
            Icons.camera_rounded,
            color: Colors.white,
            size: 32,
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
    final color = enabled ? kPrimaryColor : kTextTertiary;

    return InkWell(
      onTap: enabled ? action : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
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
