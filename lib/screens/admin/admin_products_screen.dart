import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/providers/product_provider.dart';
import 'package:shoefit/screens/admin/add_edit_product_screen.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';
import 'package:shoefit/widgets/loading_widget.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ShoeModel> _filtered(List<ShoeModel> products) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return products;
    }
    return products
        .where(
          (product) =>
              product.name.toLowerCase().contains(query) ||
              product.brand.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _deleteProduct(ShoeModel product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete product?'),
          content: Text(
            'This will permanently remove ${product.name} from the catalogue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<ProductProvider>().deleteProduct(product.id);
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('${product.name} was deleted.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();

    if (productProvider.isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading products...'),
      );
    }

    final products = _filtered(productProvider.products);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            tooltip: 'Refresh products',
            onPressed: productProvider.isSaving
                ? null
                : productProvider.refreshProducts,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Product'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search product name or brand',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: products.isEmpty
                ? const EmptyStateWidget(
                    title: 'No products available',
                    message: 'Create products to populate the catalogue.',
                    icon: Icons.inventory_2_outlined,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              product.imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 64,
                                  height: 64,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(
                                    Icons.image_not_supported_outlined,
                                  ),
                                );
                              },
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.brand} | ${product.category}\n'
                            'Stock: ${product.stock} | ${AppFormatters.currency(product.price)}',
                          ),
                          isThreeLine: true,
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        AddEditProductScreen(product: product),
                                  ),
                                );
                                return;
                              }

                              if (value == 'delete') {
                                await _deleteProduct(product);
                              }
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
