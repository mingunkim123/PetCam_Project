import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../../gallery/domain/pet_photo.dart';

class AiComparisonSheet extends StatefulWidget {
  final PetPhoto photo;

  const AiComparisonSheet({super.key, required this.photo});

  @override
  State<AiComparisonSheet> createState() => _AiComparisonSheetState();
}

class _AiComparisonSheetState extends State<AiComparisonSheet> {
  bool _showOriginal = false;

  @override
  Widget build(BuildContext context) {
    // If no upscaled bytes, just show original
    final showUpscaled =
        widget.photo.isAiProcessed && widget.photo.upscaledBytes != null;
    final displayBytes = (_showOriginal || !showUpscaled)
        ? widget.photo.originalBytes
        : widget.photo.upscaledBytes!;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: kAppBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "AI Enhanced Shot",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showUpscaled ? "Tap image to compare" : "Processing...",
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: kTextSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Image Comparison Area
          Expanded(
            child: GestureDetector(
              onTapDown: (_) {
                if (showUpscaled) setState(() => _showOriginal = true);
              },
              onTapUp: (_) {
                if (showUpscaled) setState(() => _showOriginal = false);
              },
              onTapCancel: () {
                if (showUpscaled) setState(() => _showOriginal = false);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [kSoftShadow],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(displayBytes, fit: BoxFit.cover),
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _showOriginal || !showUpscaled
                                ? "ORIGINAL"
                                : "AI UPSCALED",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Share logic
                    },
                    icon: const Icon(Icons.share_rounded),
                    label: const Text("Share"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(
                        color: kSecondaryColor.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Save logic
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.save_alt_rounded),
                    label: const Text("Save"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
