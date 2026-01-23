import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/constants.dart';
import '../home_controller.dart';
import 'ai_comparison_sheet.dart';

class FeaturedPetPhoto extends ConsumerWidget {
  const FeaturedPetPhoto({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(localPhotoControllerProvider);
    if (photos.isEmpty) return _buildPlaceholder(context, ref);

    final recentPhoto = photos.first;

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiComparisonSheet(photo: recentPhoto),
        );
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [kSoftShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(
                recentPhoto.upscaledBytes ?? recentPhoto.originalBytes,
                fit: BoxFit.cover,
              ),
              // Gradient Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // Edit Icon
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      ref.read(localPhotoControllerProvider.notifier).addPhoto(bytes);
    }
  }

  Widget _buildPlaceholder(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _pickImage(ref),
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: kSecondaryColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 48,
              color: kTextTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              "Tap to add a featured photo",
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
