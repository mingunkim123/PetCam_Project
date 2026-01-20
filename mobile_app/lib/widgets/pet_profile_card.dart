import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/riverpod_providers.dart';
import '../models/pet_profile.dart';

class PetProfileCard extends ConsumerWidget {
  const PetProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petState = ref.watch(petProfileProvider);

    return petState.when(
      data: (profile) => _buildCard(context, ref, profile),
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildCard(BuildContext context, WidgetRef ref, PetProfile profile) {
    return GestureDetector(
      onTap: () => _showEditDialog(context, ref, profile),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(kPaddingM),
        decoration: BoxDecoration(
          color: kCardBackground,
          borderRadius: BorderRadius.circular(kBorderRadiusL),
          boxShadow: [kSoftShadow],
        ),
        child: Row(
          children: [
            // Profile Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kAppBackground,
                border: Border.all(
                  color: kSecondaryColor.withOpacity(0.2),
                  width: 2,
                ),
                image: profile.imagePath.isNotEmpty
                    ? DecorationImage(
                        image: FileImage(File(profile.imagePath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: profile.imagePath.isEmpty
                  ? const Icon(Icons.pets, color: kTextTertiary, size: 40)
                  : null,
            ),
            const SizedBox(width: kPaddingM),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${profile.breed} • ${profile.age}살",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildInfoChip(
                        context,
                        Icons.monitor_weight_rounded,
                        profile.weight,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        context,
                        Icons.favorite_rounded,
                        profile.heartRate,
                        color: kAccentColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Edit Icon
            const Icon(Icons.edit_rounded, color: kTextTertiary, size: 20),
          ],
        ),
      ),
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
        color: (color ?? kSecondaryColor).withOpacity(0.1),
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
                  .read(petProfileProvider.notifier)
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
