import 'package:flutter/material.dart';

class EmptyPhotoState extends StatelessWidget {
  const EmptyPhotoState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pets_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text("아직 촬영된 사진이 없습니다.", style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w500)),
          Text("하단 셔터를 눌러 강아지를 찍어보세요!", style: TextStyle(color: Colors.grey[300], fontSize: 12)),
        ],
      ),
    );
  }
}
