import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/store/domain/store_item.dart';

class StoreService {
  Future<List<StoreItem>> fetchItems() async {
    // 실제 API 호출 대신 더미 데이터 반환
    await Future.delayed(const Duration(milliseconds: 500)); // 네트워크 지연 시뮬레이션

    return [
      StoreItem(
        id: '1',
        name: '프리미엄 닭가슴살 간식',
        description: '국내산 닭가슴살 100% 무첨가',
        price: 15000,
        imageUrl: 'https://picsum.photos/200/200?random=1',
        category: 'food',
      ),
      StoreItem(
        id: '2',
        name: '말랑말랑 삑삑이 장난감',
        description: '강아지가 좋아하는 소리가 나는 장난감',
        price: 8900,
        imageUrl: 'https://picsum.photos/200/200?random=2',
        category: 'toy',
      ),
      StoreItem(
        id: '3',
        name: '편안한 마약 방석',
        description: '잠이 솔솔 오는 푹신한 방석',
        price: 35000,
        imageUrl: 'https://picsum.photos/200/200?random=3',
        category: 'living',
      ),
      StoreItem(
        id: '4',
        name: '유기농 고구마 스틱',
        description: '식이섬유가 풍부한 건강 간식',
        price: 12000,
        imageUrl: 'https://picsum.photos/200/200?random=4',
        category: 'food',
      ),
      StoreItem(
        id: '5',
        name: '자동 급식기',
        description: '스마트폰으로 제어하는 자동 급식기',
        price: 89000,
        imageUrl: 'https://picsum.photos/200/200?random=5',
        category: 'living',
      ),
      StoreItem(
        id: '6',
        name: '튼튼한 리드줄',
        description: '3M 길이조절 가능한 자동 리드줄',
        price: 18000,
        imageUrl: 'https://picsum.photos/200/200?random=6',
        category: 'walk',
      ),
    ];
  }
}

final storeServiceProvider = Provider<StoreService>((ref) {
  return StoreService();
});
