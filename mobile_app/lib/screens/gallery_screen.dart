import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import '../providers/riverpod_providers.dart';

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(serverPhotosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("앨범")),
      body: photosAsync.when(
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(child: Text("아직 찍은 사진이 없어요 📸"));
          }
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
              final aiService = ref.read(aiServiceProvider);
              final imageUrl = aiService.getPhotoUrl(photo['id']);

              return GestureDetector(
                onTap: () => _showPhotoOptions(context, ref, photo),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.refresh(serverPhotosProvider),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _showPhotoOptions(BuildContext context, WidgetRef ref, dynamic photo) {
    final aiService = ref.read(aiServiceProvider);

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
                aiService.getPhotoUrl(photo['id']),
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
                      final url = aiService.getPhotoUrl(photo['id']);
                      final bytes = await aiService.downloadPhoto(url);
                      if (bytes != null) {
                        try {
                          await Gal.putImageBytes(bytes);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("✅ 갤러리에 저장되었습니다!")),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          debugPrint(e.toString());
                          if (context.mounted) {
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
                      bool success = await aiService.deletePhoto(photo['id']);
                      if (success) {
                        if (context.mounted) {
                          Navigator.pop(context);
                          // Refresh the provider
                          ref.refresh(serverPhotosProvider);
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
