import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import 'cache_manager_provider.dart';

part 'order_history_provider.g.dart';

const _orderHistoryKey = 'order_history';
const _uuid = Uuid();

@riverpod
class OrderHistory extends _$OrderHistory {
  @override
  FutureOr<IList<Order>> build() async {
    final cache = await ref.watch(cacheManagerProvider.future);
    final orders = await cache.readList<Order>(_orderHistoryKey, fromMap: Order.fromMap);
    return orders?.toIList() ?? IList();
  }

  Future<void> addOrder(List<CartItem> items, double total) async {
    final order = Order(
      id: _uuid.v4(),
      items: items,
      total: total,
      date: DateTime.now(),
    );

    await update((old) async {
      final newList = [order, ...old];
      final cache = await ref.read(cacheManagerProvider.future);
      await cache.saveList(
        _orderHistoryKey,
        value: newList,
        toMap: (e) => e.toMap(),
      );
      return newList.toIList();
    });
  }
}
