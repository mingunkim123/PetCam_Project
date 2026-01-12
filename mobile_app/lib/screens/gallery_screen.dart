import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import '../services/ai_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final AiService _aiService = AiService();
  late Future<List<dynamic>> _photosFuture;

  @override
  void initState() {
    super.initState();
    _photosFuture = _aiService.fetchPhotos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("앨범")),
      body: FutureBuilder<List<dynamic>>(
        future: _photosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("아직 찍은 사진이 없어요 📸"));
          }

          final photos = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.0,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              final imageUrl = _aiService.getPhotoUrl(photo['id']);

              return GestureDetector(
                onTap: () => _showPhotoOptions(context, photo),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image, color: Colors.grey),
                        ),
                      );
                    },
                    errorBuilder: (ctx, err, stack) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _photosFuture = _aiService.fetchPhotos();
          });
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, dynamic photo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                _aiService.getPhotoUrl(photo['id']),
                fit: BoxFit.cover,
                height: 250,
                width: double.infinity,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 저장 버튼
                  IconButton(
                    icon: const Icon(
                      Icons.download_rounded,
                      size: 32,
                      color: Colors.blue,
                    ),
                    onPressed: () async {
                      final url = _aiService.getPhotoUrl(photo['id']);
                      final bytes = await _aiService.downloadPhoto(url);
                      if (bytes != null) {
                        try {
                          await Gal.putImageBytes(bytes);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ 갤러리에 저장되었습니다!")),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          print(e);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("❌ 저장 권한이 필요합니다.")),
                            );
                          }
                        }
                      }
                    },
                  ),
                  // 삭제 버튼
                  IconButton(
                    icon: const Icon(
                      Icons.delete_rounded,
                      size: 32,
                      color: Colors.red,
                    ),
                    onPressed: () async {
                      bool success = await _aiService.deletePhoto(photo['id']);
                      if (success) {
                        if (mounted) {
                          Navigator.pop(context);
                          setState(() {
                            _photosFuture = _aiService.fetchPhotos();
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("🗑️ 사진이 삭제되었습니다.")),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
