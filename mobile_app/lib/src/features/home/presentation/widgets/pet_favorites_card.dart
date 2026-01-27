import 'package:flutter/material.dart';
import '../../../../core/constants/constants.dart';
import '../../domain/pet_profile.dart';

class PetFavoritesCard extends StatelessWidget {
  final PetProfile profile;

  const PetFavoritesCard({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [kSoftShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Favorites",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: kTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFavoriteItem(
            context,
            icon: Icons.map_rounded,
            label: "Course",
            value: profile.favoriteCourse,
            imagePath: profile.favoriteCourseImage,
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildFavoriteItem(
            context,
            icon: Icons.restaurant_rounded,
            label: "Food",
            value: profile.favoriteFood,
            imagePath: profile.favoriteFoodImage,
            color: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildFavoriteItem(
            context,
            icon: Icons.home_rounded,
            label: "Place",
            value: profile.favoritePlace,
            imagePath: profile.favoritePlaceImage,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String imagePath,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kAppBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imagePath,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 60,
                  height: 60,
                  color: color.withValues(alpha: 0.1),
                  child: Icon(icon, color: color),
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 14, color: kTextSecondary),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: kTextSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kTextPrimary,
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
