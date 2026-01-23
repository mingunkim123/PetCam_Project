import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/store_repository.dart';
import '../domain/store_item.dart';

class StoreController extends AsyncNotifier<List<StoreItem>> {
  @override
  Future<List<StoreItem>> build() async {
    final repository = ref.read(storeRepositoryProvider);
    return repository.fetchItems();
  }
}

final storeControllerProvider =
    AsyncNotifierProvider<StoreController, List<StoreItem>>(
      StoreController.new,
    );
