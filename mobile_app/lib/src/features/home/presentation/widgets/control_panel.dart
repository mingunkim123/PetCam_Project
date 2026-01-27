import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/constants.dart';
import '../../../../services/ble_service.dart';

class ControlPanel extends ConsumerStatefulWidget {
  const ControlPanel({super.key});

  @override
  ConsumerState<ControlPanel> createState() => _ControlPanelState();
}

class _ControlPanelState extends ConsumerState<ControlPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleService = BleService();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: kSpaceL, vertical: kSpaceM),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kRadiusFull),
        boxShadow: [
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: kPrimaryColor.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Preview Button
          _ControlButton(
            icon: Icons.visibility_rounded,
            tooltip: '미리보기',
            onTap: () {
              HapticFeedback.lightImpact();
              bleService.sendPreviewCommand();
            },
          ),

          const SizedBox(width: kSpaceM),

          // Main Capture Button
          GestureDetector(
            onTapDown: (_) {
              _animationController.forward();
              setState(() => _isPressed = true);
            },
            onTapUp: (_) {
              _animationController.reverse();
              setState(() => _isPressed = false);
              HapticFeedback.mediumImpact();
              bleService.sendSnapCommand();
            },
            onTapCancel: () {
              _animationController.reverse();
              setState(() => _isPressed = false);
            },
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                  gradient: kPrimaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: kSecondaryColor.withOpacity(_isPressed ? 0.2 : 0.4),
                      blurRadius: _isPressed ? 8 : 16,
                      offset: Offset(0, _isPressed ? 4 : 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer ring
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    // Icon
                    Icon(
                      Icons.camera_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: kSpaceM),

          // Burst Mode Button
          _ControlButton(
            icon: Icons.burst_mode_rounded,
            tooltip: '연속 촬영',
            onTap: () {
              HapticFeedback.lightImpact();
              bleService.sendBurstCommand();
            },
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_ControlButton> createState() => _ControlButtonState();
}

class _ControlButtonState extends State<_ControlButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) {
        setState(() => _isHovered = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isHovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedContainer(
          duration: kDurationFast,
          padding: const EdgeInsets.all(kSpaceM),
          decoration: BoxDecoration(
            color: _isHovered
                ? kSecondaryColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(kRadiusM),
          ),
          child: Icon(
            widget.icon,
            color: _isHovered ? kSecondaryColor : kTextSecondary,
            size: 24,
          ),
        ),
      ),
    );
  }
}
