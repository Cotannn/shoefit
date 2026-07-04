import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/screens/customer/order_detail_screen.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';
import 'package:shoefit/widgets/loading_widget.dart';
import 'package:shoefit/widgets/order_card.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.isLoading) {
      return const Scaffold(body: LoadingWidget(message: 'Loading orders...'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: orderProvider.orders.isEmpty
          ? const EmptyStateWidget(
              title: 'No orders yet',
              message: 'Your completed checkout orders will appear here.',
              icon: Icons.receipt_long_outlined,
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              itemCount: orderProvider.orders.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final order = orderProvider.orders[index];
                return OrderCard(
                  order: order,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order: order),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
