import 'dart:io';
import 'package:flutter/material.dart';
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
          padding: const EdgeInsets.all(kPaddingM),
          decoration: BoxDecoration(
            color: kCardBackground,
            borderRadius: BorderRadius.circular(kBorderRadiusL),
            boxShadow: [kSoftShadow],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Profile Image
                  GestureDetector(
                    onTap: () => _pickImage(context, ref, profile),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: kSecondaryColor.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: profile.imagePath.isNotEmpty
                              ? FileImage(File(profile.imagePath))
                              : null,
                          child: profile.imagePath.isEmpty
                              ? const Icon(
                                  Icons.pets,
                                  size: 30,
                                  color: kSecondaryColor,
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: kPrimaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              profile.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.edit_rounded,
                                size: 20,
                                color: kTextSecondary,
                              ),
                              onPressed: () =>
                                  _showEditDialog(context, ref, profile),
                            ),
                          ],
                        ),
                        Text(
                          "${profile.breed} • ${profile.age}살",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Chips
              Row(
                children: [
                  _buildInfoChip(
                    context,
                    Icons.monitor_weight_rounded,
                    "${profile.weight}kg",
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    context,
                    Icons.favorite_rounded,
                    "${profile.heartRate} bpm",
                    color: Colors.redAccent,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? kSecondaryColor).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? kSecondaryColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color ?? kSecondaryColor,
              fontWeight: FontWeight.bold,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Profile"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: breedController,
                decoration: const InputDecoration(labelText: "Breed"),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: weightController,
                decoration: const InputDecoration(labelText: "Weight"),
              ),
              TextField(
                controller: hrController,
                decoration: const InputDecoration(labelText: "Avg Heart Rate"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ref
                  .read(petControllerProvider.notifier)
                  .updateProfile(
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
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
