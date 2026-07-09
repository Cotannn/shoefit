import 'package:flutter/material.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/order_model.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    this.trailing,
  });

  final OrderModel order;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(order.orderStatus);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${_shortOrderId(order.orderId)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  trailing ??
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          order.orderStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppFormatters.date(order.orderDate),
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                '${order.itemCount} item(s) • ${order.paymentStatus}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                AppFormatters.currency(order.totalPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!order.isCancelled) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (order.statusStep + 1) / 5,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE8EDF4),
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.canConfirmReceipt
                            ? 'Action needed: confirm receipt'
                            : _statusHelper(order),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: order.canConfirmReceipt
                              ? const Color(0xFF118B50)
                              : null,
                          fontWeight: order.canConfirmReceipt
                              ? FontWeight.w800
                              : null,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _shortOrderId(String orderId) {
    final trimmed = orderId.trim();
    if (trimmed.isEmpty) {
      return 'ORDER';
    }

    final length = trimmed.length < 6 ? trimmed.length : 6;
    return trimmed.substring(0, length).toUpperCase();
  }
}

String _statusHelper(OrderModel order) {
  switch (order.normalizedStatus) {
    case 'packed':
      return 'Packed and preparing to ship';
    case 'shipped':
      return 'Parcel is on the way';
    case 'delivered':
      return 'Delivered to your address';
    case 'completed':
      return 'Purchase completed';
    default:
      return 'Order is being processed';
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
