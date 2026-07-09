import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/screens/customer/order_detail_screen.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';
import 'package:shoefit/widgets/loading_widget.dart';
import 'package:shoefit/widgets/order_card.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _filter = 'All';

  List<OrderModel> _filtered(List<OrderModel> orders) {
    return orders.where((order) {
      switch (_filter) {
        case 'Active':
          return order.isActive && !order.isDelivered;
        case 'Delivered':
          return order.isDelivered;
        case 'Completed':
          return order.isCompleted;
        case 'Cancelled':
          return order.isCancelled;
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    if (provider.isLoading && provider.orders.isEmpty) {
      return const Scaffold(body: LoadingWidget(message: 'Loading orders...'));
    }

    final orders = _filtered(provider.orders);
    final activeCount = provider.orders
        .where((order) => order.isActive && !order.isDelivered)
        .length;
    final awaitingCount = provider.orders
        .where((order) => order.canConfirmReceipt)
        .length;

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: provider.orders.isEmpty
          ? const EmptyStateWidget(
              title: 'No orders yet',
              message: 'Your purchases and delivery updates will appear here.',
              icon: Icons.receipt_long_outlined,
            )
          : Column(
              children: [
                if (activeCount > 0 || awaitingCount > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B132B), Color(0xFF19345A)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0x22FFFFFF),
                            child: Icon(
                              Icons.local_shipping_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              awaitingCount > 0
                                  ? '$awaitingCount order(s) need your receipt confirmation'
                                  : '$activeCount order(s) are being prepared or delivered',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.customerOrderFilters.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = AppConstants.customerOrderFilters[index];
                      return ChoiceChip(
                        label: Text(filter),
                        selected: _filter == filter,
                        onSelected: (_) => setState(() => _filter = filter),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: orders.isEmpty
                      ? const EmptyStateWidget(
                          title: 'No orders here',
                          message: 'Choose another order status to see more.',
                          icon: Icons.filter_alt_off_outlined,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          itemCount: orders.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final order = orders[index];
                            return OrderCard(
                              order: order,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OrderDetailScreen(order: order),
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
