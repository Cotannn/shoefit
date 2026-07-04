import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/services/order_service.dart';
import 'package:shoefit/widgets/loading_widget.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final OrderModel order;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late final Future<OrderModel> _orderFuture;

  @override
  void initState() {
    super.initState();
    if (widget.order.items.isNotEmpty) {
      _orderFuture = Future<OrderModel>.value(widget.order);
      return;
    }

    _orderFuture = context
        .read<OrderService>()
        .fetchOrderDetail(
          userId: widget.order.userId,
          orderId: widget.order.orderId,
        )
        .catchError((_) => widget.order);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OrderModel>(
      future: _orderFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: LoadingWidget(message: 'Loading order details...'),
          );
        }

        final order = snapshot.data ?? widget.order;
        return Scaffold(
          appBar: AppBar(title: const Text('Order Details')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderId}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      _DetailLine(label: 'Customer', value: order.customerName),
                      _DetailLine(label: 'Phone', value: order.customerPhone),
                      _DetailLine(
                        label: 'Delivery address',
                        value: order.deliveryAddress,
                      ),
                      _DetailLine(
                        label: 'Order date',
                        value: AppFormatters.dateTime(order.orderDate),
                      ),
                      _DetailLine(
                        label: 'Payment method',
                        value: order.paymentMethod,
                      ),
                      _DetailLine(
                        label: 'Payment status',
                        value: order.paymentStatus,
                      ),
                      _DetailLine(
                        label: 'Order status',
                        value: order.orderStatus,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ordered items',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (order.items.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('No item details returned by the API.'),
                  ),
                ),
              ...order.items.map(
                (item) => Card(
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      '${item.brand} - Size ${item.selectedSize} - Qty ${item.quantity}',
                    ),
                    trailing: Text(AppFormatters.currency(item.totalPrice)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                        label: 'Shipping fee',
                        value: AppFormatters.currency(order.shippingFee),
                      ),
                      _DetailLine(
                        label: 'Total price',
                        value: AppFormatters.currency(order.totalPrice),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(value, textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}
