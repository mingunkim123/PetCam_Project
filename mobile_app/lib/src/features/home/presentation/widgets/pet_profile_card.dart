import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/pet_profile.dart';
import '../home_controller.dart';

class PetProfileCard extends ConsumerWidget {
  const PetProfileCard({super.key});

  Future<void> _pickImage(
    BuildContext context,
    WidgetRef ref,
    PetProfile profile,
  ) async {
    HapticFeedback.selectionClick();
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      ref
          .read(petControllerProvider.notifier)
          .updateProfile(profile.copyWith(imagePath: image.path));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petControllerProvider);

    return petState.when(
      data: (profile) {
        return Container(
          padding: const EdgeInsets.all(kSpaceL),
          decoration: BoxDecoration(
            color: kCardBackground,
            borderRadius: BorderRadius.circular(kRadiusXXL),
            boxShadow: [kShadowM, kShadowS],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile Image with gradient border
                  GestureDetector(
                    onTap: () => _pickImage(context, ref, profile),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: kPrimaryGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: kCardBackground,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 32,
                          backgroundColor: kSurfaceElevated,
                          backgroundImage: profile.imagePath.isNotEmpty
                              ? FileImage(File(profile.imagePath))
                              : null,
                          child: profile.imagePath.isEmpty
                              ? const Icon(
                                  Icons.pets_rounded,
                                  size: 30,
                                  color: kSecondaryColor,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: kSpaceL),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            _buildEditButton(context, ref, profile),
                          ],
                        ),
                        const SizedBox(height: kSpaceXXS),
                        Row(
                          children: [
                            Icon(
                              Icons.pets_rounded,
                              size: 14,
                              color: kTextTertiary,
                            ),
                            const SizedBox(width: kSpaceXS),
                            Text(
                              "${profile.breed}",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: kTextSecondary),
                            ),
                            Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: kSpaceS,
                              ),
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: kTextTertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              "${profile.age}살",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: kTextSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: kSpaceL),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.monitor_weight_rounded,
                      label: '체중',
                      value: "${profile.weight}kg",
                      color: kAccentOrange,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: kTextMuted.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      context,
                      icon: Icons.favorite_rounded,
                      label: '심박수',
                      value: "${profile.heartRate}",
                      suffix: 'bpm',
                      color: kAccentColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => _buildLoadingState(),
      error: (err, stack) => _buildErrorState(context, err),
    );
  }

  Widget _buildEditButton(
    BuildContext context,
    WidgetRef ref,
    PetProfile profile,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showEditDialog(context, ref, profile);
      },
      child: Container(
        padding: const EdgeInsets.all(kSpaceS),
        decoration: BoxDecoration(
          color: kSurfaceElevated,
          borderRadius: BorderRadius.circular(kRadiusS),
        ),
        child: const Icon(
          Icons.edit_rounded,
          size: 18,
          color: kTextSecondary,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? suffix,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(kSpaceS),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(kRadiusS),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: kSpaceM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: kTextTertiary,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (suffix != null) ...[
                  const SizedBox(width: kSpaceXXS),
                  Text(
                    suffix,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: kTextTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(kSpaceXXL),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(kRadiusXXL),
        boxShadow: [kShadowS],
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: kSecondaryColor,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object err) {
    return Container(
      padding: const EdgeInsets.all(kSpaceL),
      decoration: BoxDecoration(
        color: kErrorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(kRadiusXXL),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: kErrorColor),
          const SizedBox(width: kSpaceM),
          Expanded(
            child: Text(
              'Error: $err',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: kErrorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    PetProfile profile,
  ) {
    final nameController = TextEditingController(text: profile.name);
    final ageController = TextEditingController(text: profile.age);
    final weightController = TextEditingController(text: profile.weight);
    final breedController = TextEditingController(text: profile.breed);
    final hrController = TextEditingController(text: profile.heartRate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: kSpaceXXL,
          right: kSpaceXXL,
          top: kSpaceXXL,
          bottom: MediaQuery.of(context).viewInsets.bottom + kSpaceXXL,
        ),
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(kRadiusXXL),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kTextMuted,
                    borderRadius: BorderRadius.circular(kRadiusFull),
                  ),
                ),
              ),
              const SizedBox(height: kSpaceXXL),

              // Title
              Text(
                '프로필 수정',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: kSpaceXXL),

              // Fields
              _buildEditField(
                controller: nameController,
                label: '이름',
                icon: Icons.badge_rounded,
              ),
              const SizedBox(height: kSpaceL),
              _buildEditField(
                controller: breedController,
                label: '품종',
                icon: Icons.pets_rounded,
              ),
              const SizedBox(height: kSpaceL),
              Row(
                children: [
                  Expanded(
                    child: _buildEditField(
                      controller: ageController,
                      label: '나이',
                      icon: Icons.cake_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: kSpaceL),
                  Expanded(
                    child: _buildEditField(
                      controller: weightController,
                      label: '체중 (kg)',
                      icon: Icons.monitor_weight_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: kSpaceL),
              _buildEditField(
                controller: hrController,
                label: '평균 심박수',
                icon: Icons.favorite_rounded,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: kSpaceXXL),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: kSpaceL),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        ref.read(petControllerProvider.notifier).updateProfile(
                          profile.copyWith(
                            name: nameController.text,
                            age: ageController.text,
                            weight: weightController.text,
                            breed: breedController.text,
                            heartRate: hrController.text,
                          ),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('저장'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }
}
