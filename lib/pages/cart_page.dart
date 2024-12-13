import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/cart_provider.dart';
import '../providers/order_history_provider.dart';

class CartPage extends HookConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartAsync = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          IconButton(
            icon: const Icon(Icons.remove_shopping_cart),
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
            },
          ),
        ],
      ),
      body: cartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (cartItems) {
          if (cartItems.isEmpty) {
            return const Center(
              child: Text('Your cart is empty'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    return Dismissible(
                      key: Key(item.product.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (_) {
                        for (var i = 0; i < item.quantity; i++) {
                          ref.read(cartProvider.notifier).removeItem(item.product.id);
                        }
                      },
                      child: ListTile(
                        leading: SizedBox(
                          width: 56,
                          height: 56,
                          child: CachedNetworkImage(
                            imageUrl: item.product.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                          ),
                        ),
                        title: Text(item.product.name),
                        subtitle: Text('\$${item.product.price.toStringAsFixed(2)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                ref.read(cartProvider.notifier).removeItem(item.product.id);
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                ref.read(cartProvider.notifier).addItem(item.product);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity)).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    FilledButton(
                      onPressed: cartItems.isEmpty
                          ? null
                          : () async {
                              // Show confirmation dialog
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Confirm Checkout'),
                                  content: Text(
                                      'Total amount: \$${cartItems.fold(0.0, (sum, item) => sum + (item.product.price * item.quantity)).toStringAsFixed(2)}\n\nProceed with checkout?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Confirm'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;

                              // Show loading indicator
                              if (!context.mounted) return;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                // Process the order
                                final total = cartItems.fold(
                                  0.0,
                                  (sum, item) => sum + (item.product.price * item.quantity),
                                );

                                // Add to order history
                                await ref
                                    .read(orderHistoryProvider.notifier)
                                    .addOrder(cartItems.toList(), total);

                                // Clear the cart
                                await ref.read(cartProvider.notifier).clearCart();

                                // Close loading indicator
                                if (!context.mounted) return;
                                Navigator.pop(context);

                                // Show success message
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order placed successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } catch (e) {
                                // Close loading indicator
                                if (!context.mounted) return;
                                Navigator.pop(context);

                                // Show error message
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 4)
            ],
          );
        },
      ),
    );
  }
}
