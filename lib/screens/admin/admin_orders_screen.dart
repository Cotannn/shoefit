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
  final Set<String> _updatingOrders = {};
  String _statusFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _filteredOrders(List<OrderModel> orders) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = orders.where((order) {
      final matchesQuery =
          query.isEmpty ||
          order.orderId.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.customerPhone.toLowerCase().contains(query) ||
          order.deliveryAddress.toLowerCase().contains(query);
      final matchesStatus =
          _statusFilter == 'All' || order.orderStatus == _statusFilter;
      return matchesQuery && matchesStatus;
    }).toList();
    filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    return filtered;
  }

  Future<void> _requestStatusUpdate(OrderModel order, String status) async {
    if (status == order.orderStatus ||
        _updatingOrders.contains(order.orderId)) {
      return;
    }

    final isCancellation = status == 'Cancelled';
    final isDelivery = status == 'Delivered';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          isCancellation
              ? Icons.cancel_outlined
              : isDelivery
              ? Icons.local_shipping_outlined
              : Icons.sync_alt_rounded,
        ),
        title: Text(
          isCancellation
              ? 'Cancel order #${order.orderId}?'
              : 'Move order to $status?',
        ),
        content: Text(
          isCancellation
              ? 'This removes the order from revenue reporting. Stock is not automatically returned by the current API.'
              : isDelivery
              ? 'The customer will be asked to confirm that the parcel was received before the order becomes Completed.'
              : 'The customer will see this status on their order timeline.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep current'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isCancellation ? 'Cancel order' : 'Confirm update'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _updatingOrders.add(order.orderId));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<OrderProvider>().updateOrderStatus(
        orderId: order.orderId,
        status: status,
      );
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Order #${order.orderId} is now $status.')),
        );
      }
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingOrders.remove(order.orderId));
      }
    }
  }

  Future<void> _refresh() {
    return context.read<OrderProvider>().refreshAdminOrders();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    if (provider.isAdminLoading && provider.adminOrders.isEmpty) {
      return const Scaffold(
        body: LoadingWidget(message: 'Loading all orders...'),
      );
    }

    final orders = _filteredOrders(provider.adminOrders);
    final counts = <String, int>{'All': provider.adminOrders.length};
    for (final order in provider.adminOrders) {
      counts.update(order.orderStatus, (value) => value + 1, ifAbsent: () => 1);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order operations'),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Order, customer, phone or address',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: 1 + AppConstants.orderStatuses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = index == 0
                    ? 'All'
                    : AppConstants.orderStatuses[index - 1];
                return ChoiceChip(
                  label: Text('$status ${counts[status] ?? 0}'),
                  selected: _statusFilter == status,
                  onSelected: (_) => setState(() => _statusFilter = status),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  '${orders.length} order${orders.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  'Newest first',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: orders.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 100),
                        EmptyStateWidget(
                          title: 'No matching orders',
                          message:
                              'Try another search or choose a different status.',
                          icon: Icons.search_off_rounded,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                      itemCount: orders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final order = orders[index];
                        return _AdminOrderCard(
                          order: order,
                          isUpdating: _updatingOrders.contains(order.orderId),
                          onOpen: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OrderDetailScreen(
                                  order: order,
                                  isAdminView: true,
                                ),
                              ),
                            );
                          },
                          onStatusSelected: (status) =>
                              _requestStatusUpdate(order, status),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({
    required this.order,
    required this.isUpdating,
    required this.onOpen,
    required this.onStatusSelected,
  });

  final OrderModel order;
  final bool isUpdating;
  final VoidCallback onOpen;
  final ValueChanged<String> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    final nextStatus = _nextAdminStatus(order);
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#${order.orderId} • ${order.customerName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(AppFormatters.dateTime(order.orderDate)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  _OrderStatusBadge(status: order.orderStatus),
                ],
              ),
              const Divider(height: 26),
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 18),
                  const SizedBox(width: 7),
                  Text('${order.itemCount} item(s)'),
                  const Spacer(),
                  Text(
                    AppFormatters.currency(order.totalPrice),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    order.isPaid
                        ? Icons.verified_rounded
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: order.isPaid
                        ? const Color(0xFF118B50)
                        : const Color(0xFFE17A22),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    '${order.paymentMethod} • ${order.paymentStatus}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (order.isDelivered) ...[
                const SizedBox(height: 12),
                const _WaitingConfirmation(),
              ],
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isUpdating ? null : onOpen,
                      child: const Text('View details'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (nextStatus != null)
                    Expanded(
                      child: FilledButton(
                        onPressed: isUpdating
                            ? null
                            : () => onStatusSelected(nextStatus),
                        child: isUpdating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text('Mark $nextStatus'),
                      ),
                    )
                  else
                    PopupMenuButton<String>(
                      tooltip: 'More status actions',
                      onSelected: onStatusSelected,
                      itemBuilder: (_) => AppConstants.orderStatuses
                          .where(
                            (status) =>
                                status != order.orderStatus &&
                                status != 'Completed',
                          )
                          .map(
                            (status) => PopupMenuItem(
                              value: status,
                              child: Text('Mark $status'),
                            ),
                          )
                          .toList(),
                    ),
                ],
              ),
              if (nextStatus != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: PopupMenuButton<String>(
                    tooltip: 'Other status actions',
                    onSelected: onStatusSelected,
                    itemBuilder: (_) => AppConstants.orderStatuses
                        .where(
                          (status) =>
                              status != order.orderStatus &&
                              status != nextStatus &&
                              status != 'Completed',
                        )
                        .map(
                          (status) => PopupMenuItem(
                            value: status,
                            child: Text('Mark $status'),
                          ),
                        )
                        .toList(),
                    child: const Padding(
                      padding: EdgeInsets.fromLTRB(12, 8, 0, 0),
                      child: Text('Other actions'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaitingConfirmation extends StatelessWidget {
  const _WaitingConfirmation();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 18, color: Color(0xFF118B50)),
          SizedBox(width: 8),
          Expanded(child: Text('Waiting for customer receipt confirmation')),
        ],
      ),
    );
  }
}

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String? _nextAdminStatus(OrderModel order) {
  switch (order.normalizedStatus) {
    case 'processing':
      return 'Packed';
    case 'packed':
      return 'Shipped';
    case 'shipped':
      return 'Delivered';
    default:
      return null;
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return const Color(0xFF118B50);
    case 'delivered':
      return const Color(0xFF17A673);
    case 'shipped':
      return const Color(0xFF3765D8);
    case 'packed':
      return const Color(0xFF7B4DCC);
    case 'cancelled':
      return const Color(0xFFC43E4D);
    default:
      return const Color(0xFFE17A22);
  }
}
