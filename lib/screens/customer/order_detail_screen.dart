import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/cart_item_model.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/services/order_service.dart';
import 'package:shoefit/widgets/loading_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    required this.order,
    this.isAdminView = false,
  });

  final OrderModel order;
  final bool isAdminView;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _loadedOrder;
  bool _isLoading = false;
  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _loadedOrder = widget.order;
    if (widget.order.items.isEmpty) {
      _loadDetails();
    }
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final order = await context.read<OrderService>().fetchOrderDetail(
        userId: widget.order.userId,
        orderId: widget.order.orderId,
      );
      if (mounted) {
        setState(() => _loadedOrder = order);
      }
    } catch (_) {
      // The list payload still contains enough information to show the receipt.
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  OrderModel _liveOrder(OrderProvider provider) {
    final source = widget.isAdminView ? provider.adminOrders : provider.orders;
    for (final order in source) {
      if (order.orderId == _loadedOrder.orderId) {
        if (order.items.isEmpty && _loadedOrder.items.isNotEmpty) {
          return order.copyWith(items: _loadedOrder.items);
        }
        return order;
      }
    }
    return _loadedOrder;
  }

  Future<void> _confirmReceived(OrderModel order) async {
    final authProvider = context.read<AuthProvider>();
    final userId =
        (authProvider.user ?? authProvider.profile)?.uid.trim() ?? '';
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to confirm this order.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.inventory_rounded),
        title: const Text('Confirm parcel received?'),
        content: const Text(
          'Confirm only after your shoes have arrived. This will complete the order and notify the store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Not yet'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Yes, I received it'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _isConfirming = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<OrderProvider>().confirmOrderReceived(
        userId: userId,
        orderId: order.orderId,
      );
      if (mounted) {
        setState(() {
          _loadedOrder = order.copyWith(orderStatus: 'Completed');
        });
        messenger.showSnackBar(
          const SnackBar(content: Text('Thank you! Your order is completed.')),
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
        setState(() => _isConfirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final order = _liveOrder(provider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isAdminView ? 'Order #${order.orderId}' : 'My order',
        ),
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading order details...')
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              children: [
                _OrderHero(order: order),
                const SizedBox(height: 18),
                Text(
                  'Delivery progress',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _OrderTimeline(order: order),
                if (!widget.isAdminView && order.canConfirmReceipt) ...[
                  const SizedBox(height: 16),
                  _ReceiptConfirmationCard(
                    isLoading: _isConfirming,
                    onConfirm: () => _confirmReceived(order),
                  ),
                ],
                if (!widget.isAdminView && order.isCompleted) ...[
                  const SizedBox(height: 16),
                  const _CompletedCard(),
                ],
                const SizedBox(height: 24),
                Text(
                  'Items (${order.itemCount})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (order.items.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Item details are temporarily unavailable. Your payment summary is still shown below.',
                      ),
                    ),
                  )
                else
                  ...order.items.map((item) => _OrderItemTile(item: item)),
                const SizedBox(height: 18),
                Text(
                  'Delivery details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _IconDetail(
                          icon: Icons.person_outline_rounded,
                          title: order.customerName,
                          subtitle: order.customerPhone,
                        ),
                        const Divider(height: 28),
                        _IconDetail(
                          icon: Icons.location_on_outlined,
                          title: 'Shipping address',
                          subtitle: order.deliveryAddress,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Payment summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      children: [
                        _DetailLine(
                          label: 'Subtotal',
                          value: AppFormatters.currency(order.subtotal),
                        ),
                        _DetailLine(
                          label: 'Shipping',
                          value: AppFormatters.currency(order.shippingFee),
                        ),
                        const Divider(height: 25),
                        _DetailLine(
                          label: 'Total paid',
                          value: AppFormatters.currency(order.totalPrice),
                          isBold: true,
                        ),
                        const Divider(height: 25),
                        _DetailLine(
                          label: 'Payment',
                          value:
                              '${order.paymentMethod} • ${order.paymentStatus}',
                        ),
                        _DetailLine(
                          label: 'Reference',
                          value: order.paymentReference,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Text(
                    'Ordered ${AppFormatters.dateTime(order.orderDate)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
      bottomNavigationBar: !widget.isAdminView && order.canConfirmReceipt
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: ElevatedButton.icon(
                onPressed: _isConfirming ? null : () => _confirmReceived(order),
                icon: _isConfirming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  _isConfirming ? 'Confirming...' : 'Confirm order received',
                ),
              ),
            )
          : null,
    );
  }
}

class _OrderHero extends StatelessWidget {
  const _OrderHero({required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(order.orderStatus);
    final message = _statusMessage(order);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: .75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  order.orderStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '#${order.orderId}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            message.$1,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message.$2,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _OrderTimeline extends StatelessWidget {
  const _OrderTimeline({required this.order});

  final OrderModel order;

  static const _steps = [
    ('Order placed', 'Payment accepted and order created'),
    ('Packed', 'Your shoes are prepared for dispatch'),
    ('Shipped', 'The parcel is on the way'),
    ('Delivered', 'Parcel delivered to the address'),
    ('Completed', 'Receipt confirmed by the customer'),
  ];

  @override
  Widget build(BuildContext context) {
    if (order.isCancelled) {
      return Card(
        child: ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFFFE9EC),
            child: Icon(Icons.cancel_outlined, color: Color(0xFFC43E4D)),
          ),
          title: const Text('Order cancelled'),
          subtitle: const Text(
            'This order will not continue through fulfilment.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: _steps.indexed.map((entry) {
            final index = entry.$1;
            final step = entry.$2;
            final done = index <= order.statusStep;
            final current = index == order.statusStep;
            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: Column(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: done
                                ? const Color(0xFF118B50)
                                : const Color(0xFFE8EDF4),
                            shape: BoxShape.circle,
                            border: current
                                ? Border.all(color: Colors.white, width: 4)
                                : null,
                            boxShadow: current
                                ? const [
                                    BoxShadow(
                                      color: Color(0x33118B50),
                                      blurRadius: 0,
                                      spreadRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                          child: done
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 15,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        if (index < _steps.length - 1)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: index < order.statusStep
                                  ? const Color(0xFF118B50)
                                  : const Color(0xFFE1E6EC),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.$1,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: done ? null : Colors.black38,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            current
                                ? _currentStepMessage(order, index)
                                : step.$2,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: done ? null : Colors.black38),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  const _OrderItemTile({required this.item});

  final CartItemModel item;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 74,
                height: 74,
                child: item.imageUrl.toString().isEmpty
                    ? const ColoredBox(
                        color: Color(0xFFE8EDF4),
                        child: Icon(Icons.image_outlined),
                      )
                    : CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            const ColoredBox(color: Color(0xFFE8EDF4)),
                        errorWidget: (_, _, _) => const ColoredBox(
                          color: Color(0xFFE8EDF4),
                          child: Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text('${item.brand} • Size ${item.selectedSize}'),
                  const SizedBox(height: 7),
                  Text(
                    '${item.quantity} × ${AppFormatters.currency(item.price)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppFormatters.currency(item.totalPrice),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptConfirmationCard extends StatelessWidget {
  const _ReceiptConfirmationCard({
    required this.isLoading,
    required this.onConfirm,
  });

  final bool isLoading;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.mark_email_read_outlined, color: Color(0xFF118B50)),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Has your parcel arrived?',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Confirm receipt so the store knows this purchase was completed successfully.',
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: isLoading ? null : onConfirm,
              child: const Text('Confirm received'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  const _CompletedCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7F2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_rounded, color: Color(0xFF118B50)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Receipt confirmed. Thank you for shopping with ShoeFit!',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconDetail extends StatelessWidget {
  const _IconDetail({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor: const Color(0xFFE8EDF4),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
      color: isBold ? Theme.of(context).colorScheme.onSurface : null,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: style,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

(String, String) _statusMessage(OrderModel order) {
  switch (order.normalizedStatus) {
    case 'packed':
      return (
        'Your order is packed',
        'The store is preparing it for the delivery partner.',
      );
    case 'shipped':
      return (
        'Your shoes are on the way',
        'Estimated arrival by ${AppFormatters.date(order.estimatedDeliveryDate)}.',
      );
    case 'delivered':
      return (
        'Your parcel was delivered',
        'Please check your parcel and confirm receipt below.',
      );
    case 'completed':
      return (
        'Order completed',
        'You confirmed that this purchase arrived successfully.',
      );
    case 'cancelled':
      return (
        'Order cancelled',
        'This order is closed and will not be delivered.',
      );
    default:
      return (
        'We received your order',
        'Payment is confirmed and fulfilment will begin shortly.',
      );
  }
}

String _currentStepMessage(OrderModel order, int index) {
  if (index == 2) {
    return 'Estimated arrival by ${AppFormatters.date(order.estimatedDeliveryDate)}';
  }
  if (index == 3) {
    return 'Waiting for your receipt confirmation';
  }
  return _OrderTimeline._steps[index].$2;
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return const Color(0xFF118B50);
    case 'delivered':
      return const Color(0xFF168A73);
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
