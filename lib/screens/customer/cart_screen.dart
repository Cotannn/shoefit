import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/providers/cart_provider.dart';
import 'package:shoefit/screens/customer/catalogue_screen.dart';
import 'package:shoefit/screens/customer/checkout_screen.dart';
import 'package:shoefit/widgets/cart_item_tile.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';
import 'package:shoefit/widgets/loading_widget.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    if (cartProvider.isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Loading cart...'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: cartProvider.items.isEmpty
          ? EmptyStateWidget(
              title: 'Your cart is empty',
              message: 'Add a few pairs to start your checkout flow.',
              icon: Icons.shopping_cart_outlined,
              buttonText: 'Browse catalogue',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CatalogueScreen()),
                );
              },
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    itemCount: cartProvider.items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      final provider = context.read<CartProvider>();
                      final messenger = ScaffoldMessenger.of(context);
                      return CartItemTile(
                        item: item,
                        onIncrease: () async {
                          try {
                            await provider.incrementItem(item);
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        onDecrease: () async {
                          try {
                            await provider.decrementItem(item);
                          } catch (error) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                        onRemove: () async {
                          await provider.removeItem(item);
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 22,
                        offset: const Offset(0, -8),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Subtotal',
                          value: AppFormatters.currency(cartProvider.subtotal),
                        ),
                        const SizedBox(height: 10),
                        _SummaryRow(
                          label: 'Shipping',
                          value: AppFormatters.currency(
                            cartProvider.shippingFee,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Divider(),
                        ),
                        _SummaryRow(
                          label: 'Total',
                          value: AppFormatters.currency(cartProvider.total),
                          isBold: true,
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton(
                          onPressed: cartProvider.items.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const CheckoutScreen(),
                                    ),
                                  );
                                },
                          child: const Text('Checkout'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
    );

    return Row(
      children: [
        Text(label, style: textStyle),
        const Spacer(),
        Text(value, style: textStyle),
      ],
    );
  }
}
