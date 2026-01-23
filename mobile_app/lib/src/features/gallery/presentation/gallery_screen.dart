import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import '../data/gallery_repository.dart';
import '../domain/pet_photo.dart';
import 'gallery_controller.dart';
import 'widgets/empty_photo_state.dart';

class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key});

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("앨범"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "전체"),
              Tab(text: "좋아해요 ❤️"),
              Tab(text: "싫어해요 💔"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PhotoGrid(categoryFilter: null), // 전체
            _PhotoGrid(categoryFilter: PetPhotoCategory.like), // 좋아해요
            _PhotoGrid(categoryFilter: PetPhotoCategory.dislike), // 싫어해요
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () =>
              ref.read(galleryControllerProvider.notifier).refresh(),
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}

class _PhotoGrid extends ConsumerWidget {
  final PetPhotoCategory? categoryFilter;

  const _PhotoGrid({this.categoryFilter});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(galleryControllerProvider);
    final categories = ref.watch(photoCategoryControllerProvider);
    final photos = state.photos;
    final isLoading = state.isLoading;

    // 필터링
    final filteredPhotos = photos.where((photo) {
      final id = photo['id'];
      final category = categories[id] ?? PetPhotoCategory.none;
      if (categoryFilter == null) return true; // 전체
      return category == categoryFilter;
    }).toList();

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (!isLoading &&
            scrollInfo.metrics.pixels >=
                scrollInfo.metrics.maxScrollExtent - 200) {
          ref.read(galleryControllerProvider.notifier).fetchMore();
        }
        return false;
      },
      child: filteredPhotos.isEmpty && !isLoading
          ? const EmptyPhotoState()
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: filteredPhotos.length + (state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredPhotos.length) {
                  return const Center(child: CircularProgressIndicator());
                }

                final photo = filteredPhotos[index];
                final repository = ref.read(galleryRepositoryProvider);
                final imageUrl = repository.getPhotoUrl(photo['id']);
                final id = photo['id'];
                final currentCategory = categories[id] ?? PetPhotoCategory.none;

                return GestureDetector(
                  onTap: () => _showPhotoOptions(context, ref, photo),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
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
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (currentCategory != PetPhotoCategory.none)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Icon(
                            currentCategory == PetPhotoCategory.like
                                ? Icons.favorite
                                : Icons.heart_broken,
                            color: currentCategory == PetPhotoCategory.like
                                ? Colors.red
                                : Colors.grey,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  void _showPhotoOptions(BuildContext context, WidgetRef ref, dynamic photo) {
    final repository = ref.read(galleryRepositoryProvider);
    final id = photo['id'];

    showDialog(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final categories = ref.watch(photoCategoryControllerProvider);
            final currentCategory = categories[id] ?? PetPhotoCategory.none;

            return AlertDialog(
              contentPadding: EdgeInsets.zero,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      repository.getPhotoUrl(photo['id']),
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
                        // 좋아요 버튼
                        IconButton(
                          icon: Icon(
                            currentCategory == PetPhotoCategory.like
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Colors.red,
                            size: 32,
                          ),
                          onPressed: () {
                            ref
                                .read(photoCategoryControllerProvider.notifier)
                                .toggleCategory(id, PetPhotoCategory.like);
                          },
                        ),
                        // 싫어요 버튼
                        IconButton(
                          icon: Icon(
                            currentCategory == PetPhotoCategory.dislike
                                ? Icons.heart_broken
                                : Icons.heart_broken_outlined,
                            color: Colors.grey,
                            size: 32,
                          ),
                          onPressed: () {
                            ref
                                .read(photoCategoryControllerProvider.notifier)
                                .toggleCategory(id, PetPhotoCategory.dislike);
                          },
                        ),
                        // 저장 버튼
                        IconButton(
                          icon: const Icon(
                            Icons.download_rounded,
                            size: 32,
                            color: Colors.blue,
                          ),
                          onPressed: () async {
                            final url = repository.getPhotoUrl(photo['id']);
                            final bytes = await repository.downloadPhoto(url);
                            if (bytes != null) {
                              try {
                                await Gal.putImageBytes(bytes);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("✅ 갤러리에 저장되었습니다!"),
                                    ),
                                  );
                                  Navigator.pop(context);
                                }
                              } catch (e) {
                                debugPrint(e.toString());
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("❌ 저장 권한이 필요합니다."),
                                    ),
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
                            bool success = await repository.deletePhoto(
                              photo['id'],
                            );
                            if (success) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ref
                                    .read(galleryControllerProvider.notifier)
                                    .refresh();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("🗑️ 사진이 삭제되었습니다."),
                                  ),
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
            );
          },
        );
      },
    );
  }
}
