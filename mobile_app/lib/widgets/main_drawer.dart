import 'package:flutter/material.dart';
import '../constants.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: kPrimaryColor),
            accountName: const Text("PetCam User", style: TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: const Text("yonsei.ac.kr"), // 사장님의 소속감!
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.pets, color: kPrimaryColor, size: 40),
            ),
          ),
          _buildMenuItem(context, Icons.map_outlined, "산책 지도 (GPS)", "/map"),
          _buildMenuItem(context, Icons.photo_library_outlined, "저장된 사진", "/gallery"),
          const Divider(),
          _buildMenuItem(context, Icons.settings_outlined, "설정", null),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String? route) {
    return ListTile(
      leading: Icon(icon, color: kPrimaryColor),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () {
        Navigator.pop(context); // 드로어 닫기
        if (route != null) Navigator.pushNamed(context, route);
      },
    );
  }
}
