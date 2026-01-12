import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../models/pet_photo.dart';

class ImagePreviewList extends StatefulWidget {
  final List<PetPhoto> photos;
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
  State<ImagePreviewList> createState() => _ImagePreviewListState();
}

class _ImagePreviewListState extends State<ImagePreviewList> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.75);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.photos.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        widget.onSelect(index);
      },
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final photo = widget.photos[index];
        bool isRec = widget.recommendedIndex == index;
        bool isConf = widget.confirmedIndex == index;
        bool isActive = _currentPage == index;

        // Animation scale
        double scale = isActive ? 1.0 : 0.9;
        
        return TweenAnimationBuilder(
          tween: Tween(begin: scale, end: scale),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutBack,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: child,
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Image Card
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      isActive ? kStrongShadow : kSoftShadow,
                      if (isConf) 
                        BoxShadow(
                          color: kSecondaryColor.withOpacity(0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(
                          photo.originalBytes,
                          fit: BoxFit.cover,
                        ),
                        // Gradient Overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                        // Badges
                        if (isRec) _buildBadge("✨ AI BEST", kAccentColor),
                        if (photo.isAiProcessed) 
                          _buildBadge("✅ UPSCALED", Colors.greenAccent),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Action Button
              SizedBox(
                height: 60,
                child: isActive
                    ? AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: 1.0,
                        child: ElevatedButton.icon(
                          onPressed: () => widget.onAiUpscale(index),
                          icon: const Icon(Icons.auto_fix_high, size: 20),
                          label: Text(
                            photo.isAiProcessed ? "Re-Upscale" : "AI Upscale",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 8,
                            shadowColor: kPrimaryColor.withOpacity(0.4),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Positioned(
      top: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}