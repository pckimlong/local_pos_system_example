import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sale_product/helpers/constraint.dart';
import 'package:sale_product/providers/cache_manager_provider.dart';

import '../exports.dart';
import '../models/product.dart';

part 'product_providers.g.dart';

const _productListKey = 'product_list';

@riverpod
class ProductList extends _$ProductList {
  @override
  FutureOr<IList<Product>> build() async {
    final cache = await ref.watch(cacheManagerProvider.future);
    final productList = await cache.readList<Product>(_productListKey, fromMap: Product.fromMap);

    if (productList == null) {
      await cache.saveList(
        _productListKey,
        value: kInitialProductList.unlock,
        toMap: (e) => e.toMap(),
      );
      return kInitialProductList;
    }

    return productList.toIList();
  }

  Future<void> addItem(Product product) async {
    await update((old) async {
      final newList = [product, ...old];
      final cache = await ref.read(cacheManagerProvider.future);
      await cache.saveList(
        _productListKey,
        value: newList,
        toMap: (e) => e.toMap(),
      );

      return newList.toIList();
    });
  }

  Future<void> deleteItem(String productId) async {
    await update((old) async {
      final newList = old.where((product) => product.id != productId).toList();
      final cache = await ref.read(cacheManagerProvider.future);
      await cache.saveList(
        _productListKey,
        value: newList,
        toMap: (e) => e.toMap(),
      );

      return newList.toIList();
    });
  }

  Future<void> updateItem(Product updatedProduct) async {
    await update((old) async {
      final newList = old.map((product) => 
        product.id == updatedProduct.id ? updatedProduct : product
      ).toList();
      
      final cache = await ref.read(cacheManagerProvider.future);
      await cache.saveList(
        _productListKey,
        value: newList,
        toMap: (e) => e.toMap(),
      );

      return newList.toIList();
    });
  }
}
