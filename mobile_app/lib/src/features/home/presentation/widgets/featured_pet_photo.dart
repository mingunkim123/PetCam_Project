import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => AiComparisonSheet(photo: recentPhoto),
        );
      },
      child: Hero(
        tag: 'featured_photo',
        child: Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(kRadiusXXL),
            boxShadow: [kShadowL],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kRadiusXXL),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Image
                Image.memory(
                  recentPhoto.upscaledBytes ?? recentPhoto.originalBytes,
                  fit: BoxFit.cover,
                ),

                // Gradient Overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),

                // AI Badge
                Positioned(
                  top: kSpaceM,
                  left: kSpaceM,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: kSpaceM,
                      vertical: kSpaceXS,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(kRadiusFull),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: kAccentOrange,
                        ),
                        const SizedBox(width: kSpaceXS),
                        const Text(
                          'AI Enhanced',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Info
                Positioned(
                  bottom: kSpaceL,
                  left: kSpaceL,
                  right: kSpaceL,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '최근 촬영',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            '탭하여 AI 분석 보기',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(kSpaceM),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    HapticFeedback.selectionClick();
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
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(kRadiusXXL),
          border: Border.all(
            color: kSecondaryColor.withOpacity(0.2),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          boxShadow: [kShadowXS],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(kSpaceL),
              decoration: BoxDecoration(
                color: kSecondaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate_rounded,
                size: 40,
                color: kSecondaryColor,
              ),
            ),
            const SizedBox(height: kSpaceL),
            Text(
              "첫 번째 사진을 추가하세요",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: kTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: kSpaceXS),
            Text(
              "탭하여 갤러리에서 선택",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kTextTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
