import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/providers/favourite_provider.dart';
import 'package:shoefit/providers/product_provider.dart';
import 'package:shoefit/screens/customer/product_detail_screen.dart';
import 'package:shoefit/widgets/category_chip.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';
import 'package:shoefit/widgets/loading_widget.dart';
import 'package:shoefit/widgets/product_card.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({
    super.key,
    this.initialCategory,
    this.initialSearchQuery,
  });

  final String? initialCategory;
  final String? initialSearchQuery;

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  late final TextEditingController _searchController;
  late String _selectedCategory;
  String _sortOption = AppConstants.sortOptions.first;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.initialSearchQuery ?? '',
    );
    _selectedCategory = widget.initialCategory ?? 'All';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ShoeModel> _filteredProducts(List<ShoeModel> products) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = products.where((product) {
      final matchesQuery =
          query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.brand.toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();

    switch (_sortOption) {
      case 'Price: Low to High':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating':
        filtered.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return filtered;
  }

  Future<void> _toggleFavourite(String productId) async {
    try {
      await context.read<FavouriteProvider>().toggleFavourite(productId);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final favouriteProvider = context.watch<FavouriteProvider>();

    if (productProvider.isLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading products...'),
      );
    }

    final products = _filteredProducts(productProvider.products);

    return Scaffold(
      appBar: AppBar(title: const Text('Catalogue')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search shoe or brand',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: AppConstants.categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CategoryChip(
                          label: category,
                          isSelected: _selectedCategory == category,
                          onTap: () =>
                              setState(() => _selectedCategory = category),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _sortOption,
                  items: AppConstants.sortOptions
                      .map(
                        (option) => DropdownMenuItem(
                          value: option,
                          child: Text(option),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortOption = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Sort by',
                    prefixIcon: Icon(Icons.sort_rounded),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: products.isEmpty
                ? const EmptyStateWidget(
                    title: 'No products found',
                    message:
                        'Try adjusting your search, category, or sorting filters.',
                    icon: Icons.search_off_rounded,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.6,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isFavourite: favouriteProvider.isFavourite(product.id),
                        onFavouriteTap: () => _toggleFavourite(product.id),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onAddToCart: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailScreen(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
