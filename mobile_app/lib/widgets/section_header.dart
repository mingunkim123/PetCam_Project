import 'package:flutter/material.dart';
import '../utils/constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMoreTap;

  const SectionHeader({super.key, required this.title, this.onMoreTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kPaddingL,
        vertical: kPaddingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (onMoreTap != null)
            TextButton(
              onPressed: onMoreTap,
              child: Text(
                "More",
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: kSecondaryColor),
              ),
            ),
        ],
      ),
    );
  }
}
