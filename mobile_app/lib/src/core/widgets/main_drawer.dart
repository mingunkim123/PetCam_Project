import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/constants.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(gradient: kPrimaryGradient),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,
                  child: const Icon(
                    Icons.pets_rounded,
                    color: kSecondaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PetCam User",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "yonsei.ac.kr",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildMenuItem(context, Icons.map_rounded, "Walking Map", "/map"),
          _buildMenuItem(
            context,
            Icons.photo_library_rounded,
            "Gallery",
            "/gallery",
          ),
          _buildMenuItem(
            context,
            Icons.shopping_bag_rounded,
            "Pet Store",
            "/store",
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Divider(),
          ),
          _buildMenuItem(context, Icons.settings_rounded, "Settings", null),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title,
    String? route,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kSecondaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: kSecondaryColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: kPrimaryColor,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // 드로어 닫기
        if (route != null) context.push(route);
      },
    );
  }
}
