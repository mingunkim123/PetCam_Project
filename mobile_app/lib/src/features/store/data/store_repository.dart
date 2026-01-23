import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/store_service.dart';
import '../domain/store_item.dart';

class StoreRepository {
  final StoreService _storeService;

  StoreRepository(this._storeService);

  Future<List<StoreItem>> fetchItems() {
    return _storeService.fetchItems();
  }
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  final storeService = ref.read(storeServiceProvider);
  return StoreRepository(storeService);
});
