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
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          order.orderStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
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
                '${order.itemCount} item(s) - ${order.paymentStatus}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 10),
              Text(
                AppFormatters.currency(order.totalPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
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
