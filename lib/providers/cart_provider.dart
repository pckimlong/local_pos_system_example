import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import 'cache_manager_provider.dart';

part 'cart_provider.g.dart';

const _cartKey = 'cart_items';

@riverpod
class Cart extends _$Cart {
  @override
  FutureOr<IList<CartItem>> build() async {
    final cache = await ref.watch(cacheManagerProvider.future);
    final cartItems = await cache.readList<CartItem>(_cartKey, fromMap: CartItem.fromMap);
    return cartItems?.toIList() ?? IList();
  }

  Future<void> addItem(Product product) async {
    await update((old) async {
      final existingItemIndex = old.indexWhere((item) => item.product.id == product.id);
      final List<CartItem> newList;

      if (existingItemIndex != -1) {
        // Update quantity if item exists
        final existingItem = old[existingItemIndex];
        newList = old.toList();
        newList[existingItemIndex] = CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + 1,
        );
      } else {
        // Add new item if it doesn't exist
        newList = [...old, CartItem(product: product, quantity: 1)];
      }

      final cache = await ref.read(cacheManagerProvider.future);
      await cache.saveList(
        _cartKey,
        value: newList,
        toMap: (e) => e.toMap(),
      );

      return newList.toIList();
    });
  }

  Future<void> removeItem(String productId) async {
    await update((old) async {
      final existingItemIndex = old.indexWhere((item) => item.product.id == productId);
      if (existingItemIndex == -1) return old;

      final existingItem = old[existingItemIndex];
      final List<CartItem> newList = old.toList();

      if (existingItem.quantity > 1) {
        // Decrease quantity if more than 1
        newList[existingItemIndex] = CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity - 1,
        );
      } else {
        // Remove item if quantity would become 0
        newList.removeAt(existingItemIndex);
      }

      final cache = await ref.read(cacheManagerProvider.future);
      await cache.saveList(
        _cartKey,
        value: newList,
        toMap: (e) => e.toMap(),
      );

      return newList.toIList();
    });
  }

  Future<void> clearCart() async {
    await update((old) async {
      final cache = await ref.read(cacheManagerProvider.future);
      await cache.saveList(
        _cartKey,
        value: <CartItem>[],
        toMap: (e) => e.toMap(),
      );
      return IList();
    });
  }
}
