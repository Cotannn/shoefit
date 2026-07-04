import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/screens/customer/order_detail_screen.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';
import 'package:shoefit/widgets/loading_widget.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _searchController = TextEditingController();
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    final query = _searchController.text.trim().toLowerCase();
    return orders.where((order) {
      final matchesQuery =
          query.isEmpty ||
          order.orderId.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All' || order.orderStatus == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
  }

  Future<void> _updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<OrderProvider>().updateOrderStatus(
        orderId: orderId,
        status: status,
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Order marked as $status.')),
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
    final orderProvider = context.watch<OrderProvider>();

    if (orderProvider.isAdminLoading) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading all orders...'),
      );
    }

    final orders = _filteredOrders(orderProvider.adminOrders);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Orders')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Search order ID or customer name',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  items: ['All', ...AppConstants.orderStatuses]
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _statusFilter = value);
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Filter by order status',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: orders.isEmpty
                ? const EmptyStateWidget(
                    title: 'No matching orders',
                    message:
                        'Try a different search term or remove the status filter.',
                    icon: Icons.search_off_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '#${order.orderId}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              OrderDetailScreen(order: order),
                                        ),
                                      );
                                    },
                                    child: const Text('Open'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(order.customerName),
                              const SizedBox(height: 4),
                              Text(AppFormatters.dateTime(order.orderDate)),
                              const SizedBox(height: 4),
                              Text(
                                '${order.itemCount} item(s) - ${AppFormatters.currency(order.totalPrice)}',
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<String>(
                                initialValue: order.orderStatus,
                                items: AppConstants.orderStatuses
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) {
                                    return;
                                  }
                                  _updateOrderStatus(
                                    orderId: order.orderId,
                                    status: value,
                                  );
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Update order status',
                                ),
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
