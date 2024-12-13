import 'package:cached_network_image/cached_network_image.dart';
import 'package:sale_product/exports.dart';
import 'package:sale_product/models/product.dart';
import 'package:sale_product/providers/product_providers.dart';

class ProductPage extends HookConsumerWidget {
  const ProductPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productListAsync = ref.watch(productListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const CreateProductDialog(),
            ),
          ),
        ],
      ),
      body: productListAsync.when(
        data: (products) => products.isEmpty
            ? const Center(
                child: Text(
                  'No products available.\nClick + to add a product.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) => ProductCard(product: products[index]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class ProductCard extends ConsumerWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                SizedBox.expand(
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Center(
                      child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                    ),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => UpdateProductDialog(product: product),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (context) => DeleteProductDialog(product: product),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateProductDialog extends HookConsumerWidget {
  const CreateProductDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController();
    final priceController = useTextEditingController();
    final imageUrlController = useTextEditingController();

    return AlertDialog(
      title: const Text('Add New Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Product Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: imageUrlController,
            decoration: const InputDecoration(labelText: 'Image URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final price = double.tryParse(priceController.text) ?? 0.0;
            final product = Product(
              id: const Uuid().v4(),
              name: nameController.text,
              price: price,
              imageUrl: imageUrlController.text,
            );
            ref.read(productListProvider.notifier).addItem(product);
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}

class UpdateProductDialog extends HookConsumerWidget {
  final Product product;

  const UpdateProductDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nameController = useTextEditingController(text: product.name);
    final priceController = useTextEditingController(text: product.price.toString());
    final imageUrlController = useTextEditingController(text: product.imageUrl);

    return AlertDialog(
      title: const Text('Edit Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Product Name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: imageUrlController,
            decoration: const InputDecoration(labelText: 'Image URL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final price = double.tryParse(priceController.text) ?? 0.0;
            final updatedProduct = Product(
              id: product.id,
              name: nameController.text,
              price: price,
              imageUrl: imageUrlController.text,
            );
            ref.read(productListProvider.notifier).updateItem(updatedProduct);
            Navigator.pop(context);
          },
          child: const Text('Update'),
        ),
      ],
    );
  }
}

class DeleteProductDialog extends ConsumerWidget {
  final Product product;

  const DeleteProductDialog({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Delete Product'),
      content: const Text('Are you sure you want to delete this product?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(productListProvider.notifier).deleteItem(product.id);
            Navigator.pop(context);
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
