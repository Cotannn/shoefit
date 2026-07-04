import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/shoe_model.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.isFavourite,
    required this.onFavouriteTap,
    required this.onTap,
    this.onAddToCart,
  });

  final ShoeModel product;
  final bool isFavourite;
  final VoidCallback onFavouriteTap;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, imageUrl) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, imageUrl, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: onFavouriteTap,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            isFavourite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavourite
                                ? Colors.redAccent
                                : theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                product.brand.toUpperCase(),
                style: theme.textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    product.rating.toStringAsFixed(1),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppFormatters.currency(product.price),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton.filled(
                    onPressed: product.isOutOfStock ? null : onAddToCart,
                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      disabledBackgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
