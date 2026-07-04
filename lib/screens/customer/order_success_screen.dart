import 'package:flutter/material.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/screens/customer/customer_navigation.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 52,
                backgroundColor: Color(0xFFE6F9F7),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 68,
                  color: Color(0xFF118B50),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Order Placed Successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Order ID: ${order.orderId}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Total payment: ${AppFormatters.currency(order.totalPrice)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Payment status: ${order.paymentStatus}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const CustomerNavigation(initialIndex: 3),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('View Orders'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const CustomerNavigation(initialIndex: 0),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Continue Shopping'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
