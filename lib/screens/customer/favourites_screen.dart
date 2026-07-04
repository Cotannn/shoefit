import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/providers/favourite_provider.dart';
import 'package:shoefit/providers/product_provider.dart';
import 'package:shoefit/screens/customer/product_detail_screen.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';
import 'package:shoefit/widgets/product_card.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favouriteProvider = context.watch<FavouriteProvider>();
    final productProvider = context.watch<ProductProvider>();
    final favourites = productProvider.products
        .where((product) => favouriteProvider.isFavourite(product.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Favourites')),
      body: favourites.isEmpty
          ? const EmptyStateWidget(
              title: 'No favourites yet',
              message: 'Save shoes to compare and revisit them later.',
              icon: Icons.favorite_border_rounded,
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 0.6,
              ),
              itemCount: favourites.length,
              itemBuilder: (context, index) {
                final product = favourites[index];
                return ProductCard(
                  product: product,
                  isFavourite: true,
                  onFavouriteTap: () async {
                    await context.read<FavouriteProvider>().toggleFavourite(
                      product.id,
                    );
                  },
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
                );
              },
            ),
    );
  }
}
