import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';
import '../providers/riverpod_providers.dart';
import '../models/pet_profile.dart';

class FeaturedPetPhoto extends ConsumerWidget {
  const FeaturedPetPhoto({super.key});

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    PetProfile profile,
  ) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      ref
          .read(petProfileProvider.notifier)
          .updateProfile(profile.copyWith(featuredImagePath: image.path));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petProfileProvider);

    final profile = petState.maybeWhen(
      data: (data) => data,
      orElse: () => PetProfile.empty(),
    );
    final featuredImage = profile.featuredImagePath;

    return GestureDetector(
      onTap: () => _pickImage(context, ref, profile),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        height: 300,
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(kBorderRadiusL),
          boxShadow: [kSoftShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kBorderRadiusL),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (featuredImage.isNotEmpty)
                Image.file(
                  File(featuredImage),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildPlaceholder(context);
                  },
                )
              else
                _buildPlaceholder(context),

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
                        Colors.black.withOpacity(0.6),
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
                    color: Colors.white.withOpacity(0.2),
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

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      color: kAppBackground,
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
    );
  }
}
