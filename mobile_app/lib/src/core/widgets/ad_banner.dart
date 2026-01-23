import 'package:flutter/material.dart';
import '../constants/constants.dart';

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      color: Colors.grey[200],
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            color: Colors.blue[100],
            child: const Icon(Icons.pets, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "우리 아이 펫보험, 월 9,900원부터!",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  "병원비 걱정 없이 든든하게 지켜주세요 🛡️",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text("알아보기")),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
