import 'package:flutter/material.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("우리 아이 앨범")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
        ),
        itemCount: 0, // 나중에 실제 저장된 이미지를 불러올 로직 추가
        itemBuilder: (context, index) => Container(color: Colors.grey[200]),
      ),
    );
  }
}
