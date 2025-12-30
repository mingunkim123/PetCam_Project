import 'package:flutter/material.dart';
import '../constants.dart';

class ControlPanel extends StatelessWidget {
  final bool isConnected;
  final bool isProcessing;
  final VoidCallback onSnap;
  final VoidCallback onBurst;
  final VoidCallback onConnect;

  const ControlPanel({
    super.key,
    required this.isConnected,
    required this.isProcessing,
    required this.onSnap,
    required this.onBurst,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionBtn(onSnap, Icons.camera_alt_outlined, "단발", isConnected && !isProcessing, false),
          _buildActionBtn(onBurst, Icons.auto_awesome_motion_rounded, "연속 촬영", isConnected && !isProcessing, true),
          _buildActionBtn(onConnect, Icons.bluetooth_searching, "연결", true, false),
        ],
      ),
    );
  }

  Widget _buildActionBtn(VoidCallback? action, IconData icon, String label, bool enabled, bool primary) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? action : null,
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: enabled ? (primary ? kPrimaryColor : kBgColor) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: enabled ? (primary ? Colors.white : kPrimaryColor) : Colors.grey[400], size: 28),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: enabled ? Colors.black87 : Colors.grey)),
      ],
    );
  }
}