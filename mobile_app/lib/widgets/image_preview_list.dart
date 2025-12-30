import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/pet_photo.dart';

class ImagePreviewList extends StatelessWidget {
  final List<PetPhoto> photos;       // Uint8List에서 PetPhoto 리스트로 변경
  final int? recommendedIndex;
  final int? confirmedIndex;
  final Function(int) onSelect;
  final Function(int) onAiUpscale;

  const ImagePreviewList({
    super.key,
    required this.photos,
    required this.recommendedIndex,
    required this.confirmedIndex,
    required this.onSelect,
    required this.onAiUpscale,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        bool isRec = recommendedIndex == index;
        bool isConf = confirmedIndex == index;

        return Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Column(
            children: [
              // 이미지 카드 부분
              GestureDetector(
                onTap: () => onSelect(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isConf ? kPrimaryColor : Colors.transparent,
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isConf 
                            ? kPrimaryColor.withOpacity(0.2) 
                            : Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // 원본 이미지를 보여줌
                        Image.memory(
                          photo.originalBytes, 
                          width: 280, 
                          height: 380, 
                          fit: BoxFit.cover
                        ),
                        // AI BEST 뱃지 (추천 인덱스일 때만)
                        if (isRec) _buildBadge("✨ AI BEST", kAccentColor),
                        // AI 변환 완료 표시
                        if (photo.isAiProcessed) 
                          _buildBadge("✅ UPSCALED", Colors.greenAccent),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // 선택된 사진 하단에 나타나는 AI 변환 버튼
              if (isConf)
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: 1.0,
                  child: ElevatedButton.icon(
                    onPressed: () => onAiUpscale(index),
                    icon: const Icon(Icons.auto_fix_high, size: 20),
                    label: Text(
                      photo.isAiProcessed ? "다시 고화질 변환" : "AI 고화질 변환",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // 상단 뱃지 위젯 (BEST 컷이나 변환 여부 표시용)
  Widget _buildBadge(String text, Color color) {
    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11, 
            fontWeight: FontWeight.w900, // Error 났던 부분: w900으로 안전하게 처리
            color: Colors.black87
          ),
        ),
      ),
    );
  }
}