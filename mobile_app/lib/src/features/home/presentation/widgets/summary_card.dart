import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final Color? color; // Legacy support

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.gradient = kPrimaryGradient,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Use gradient's first color if color is provided for backward compatibility
    final effectiveGradient = color != null
        ? LinearGradient(
            colors: [color!, color!.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : gradient;

    final primaryColor = effectiveGradient.colors.first;

    return Container(
      padding: const EdgeInsets.all(kSpaceL),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kRadiusXL),
        boxShadow: [kShadowS, kShadowXS],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon with gradient background
          Container(
            padding: const EdgeInsets.all(kSpaceM),
            decoration: BoxDecoration(
              gradient: effectiveGradient,
              borderRadius: BorderRadius.circular(kRadiusM),
              boxShadow: [kColoredShadow(primaryColor, opacity: 0.3)],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: kIconM,
            ),
          ),

          const Spacer(),

          // Value
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: kSpaceXXS),

          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: kTextTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
