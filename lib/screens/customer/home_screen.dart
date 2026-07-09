import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/providers/favourite_provider.dart';
import 'package:shoefit/providers/product_provider.dart';
import 'package:shoefit/screens/customer/catalogue_screen.dart';
import 'package:shoefit/screens/customer/product_detail_screen.dart';
import 'package:shoefit/widgets/category_chip.dart';
import 'package:shoefit/widgets/loading_widget.dart';
import 'package:shoefit/widgets/product_card.dart';
import 'package:shoefit/widgets/promo_banner.dart';
import 'package:shoefit/widgets/section_title.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCatalogue({String? category, String? searchQuery}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogueScreen(
          initialCategory: category,
          initialSearchQuery: searchQuery,
        ),
      ),
    );
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
        body: LoadingWidget(message: 'Loading catalogue...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('ShoeFit'),
            SizedBox(height: 2),
            Text(
              'Premium sneaker store',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: productProvider.refreshProducts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Search by shoe or brand',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onSubmitted: (value) {
                _openCatalogue(searchQuery: value.trim());
              },
            ),
            const SizedBox(height: 20),
            PromoBanner(
              featuredProduct: productProvider.featuredProducts.isNotEmpty
                  ? productProvider.featuredProducts.first
                  : productProvider.newArrivals.isNotEmpty
                  ? productProvider.newArrivals.first
                  : null,
              onExploreTap: () => _openCatalogue(),
            ),
            const SizedBox(height: 24),
            const SectionTitle(title: 'Shop by category'),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: AppConstants.productCategories
                    .map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: CategoryChip(
                          label: category,
                          isSelected: false,
                          onTap: () => _openCatalogue(category: category),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 28),
            _ProductSection(
              title: 'Featured products',
              products: productProvider.featuredProducts,
              favouriteProvider: favouriteProvider,
              onViewAllTap: () => _openCatalogue(),
              onFavouriteTap: _toggleFavourite,
            ),
            const SizedBox(height: 28),
            _ProductSection(
              title: 'New arrivals',
              products: productProvider.newArrivals,
              favouriteProvider: favouriteProvider,
              onViewAllTap: () => _openCatalogue(),
              onFavouriteTap: _toggleFavourite,
            ),
            const SizedBox(height: 28),
            _ProductSection(
              title: 'Popular picks',
              products: productProvider.popularProducts,
              favouriteProvider: favouriteProvider,
              onViewAllTap: () => _openCatalogue(),
              onFavouriteTap: _toggleFavourite,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSection extends StatelessWidget {
  const _ProductSection({
    required this.title,
    required this.products,
    required this.favouriteProvider,
    required this.onViewAllTap,
    required this.onFavouriteTap,
  });

  final String title;
  final List<ShoeModel> products;
  final FavouriteProvider favouriteProvider;
  final VoidCallback onViewAllTap;
  final Future<void> Function(String productId) onFavouriteTap;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          title: title,
          actionLabel: 'View all',
          onActionTap: onViewAllTap,
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 360,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: 230,
                child: ProductCard(
                  product: product,
                  isFavourite: favouriteProvider.isFavourite(product.id),
                  onFavouriteTap: () => onFavouriteTap(product.id),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                  onAddToCart: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
