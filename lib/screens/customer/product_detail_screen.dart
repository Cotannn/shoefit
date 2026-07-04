import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/providers/cart_provider.dart';
import 'package:shoefit/providers/favourite_provider.dart';
import 'package:shoefit/screens/customer/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final ShoeModel product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int? _selectedSize;
  int _quantity = 1;

  Future<void> _toggleFavourite() async {
    try {
      await context.read<FavouriteProvider>().toggleFavourite(
        widget.product.id,
      );
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

  Future<void> _handleAddToCart({required bool buyNow}) async {
    final selectedSize = _selectedSize;
    if (selectedSize == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a shoe size first.')),
      );
      return;
    }

    if (widget.product.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This product is out of stock.')),
      );
      return;
    }

    try {
      await context.read<CartProvider>().addToCart(
        shoe: widget.product,
        selectedSize: selectedSize,
        quantity: _quantity,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to cart.')));

      if (buyNow) {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CheckoutScreen()));
      }
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
    final favouriteProvider = context.watch<FavouriteProvider>();
    final cartProvider = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            actions: [
              IconButton(
                onPressed: _toggleFavourite,
                icon: Icon(
                  favouriteProvider.isFavourite(widget.product.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: favouriteProvider.isFavourite(widget.product.id)
                      ? Colors.redAccent
                      : theme.colorScheme.primary,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: widget.product.imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: Icon(Icons.image_not_supported_outlined, size: 42),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.brand.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.name,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        AppFormatters.currency(widget.product.price),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.star_rounded, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        widget.product.rating.toStringAsFixed(1),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _InfoPill(label: widget.product.category),
                      _InfoPill(label: widget.product.material),
                      _InfoPill(label: widget.product.suitableUse),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.product.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.7),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Available sizes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: widget.product.sizes.map((size) {
                      final isSelected = _selectedSize == size;
                      return ChoiceChip(
                        label: Text(size.toString()),
                        selected: isSelected,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _selectedSize = size),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(
                        'Quantity',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _quantity > 1
                                  ? () => setState(() => _quantity--)
                                  : null,
                              icon: const Icon(Icons.remove_rounded),
                            ),
                            Text(
                              '$_quantity',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            IconButton(
                              onPressed: _quantity < widget.product.stock
                                  ? () => setState(() => _quantity++)
                                  : null,
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.product.stock > 0
                        ? 'Stock available: ${widget.product.stock}'
                        : 'Out of Stock',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: widget.product.stock > 0
                          ? const Color(0xFF118B50)
                          : Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      cartProvider.isMutating || widget.product.isOutOfStock
                      ? null
                      : () => _handleAddToCart(buyNow: false),
                  child: const Text('Add to Cart'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      cartProvider.isMutating || widget.product.isOutOfStock
                      ? null
                      : () => _handleAddToCart(buyNow: true),
                  child: const Text('Buy Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
