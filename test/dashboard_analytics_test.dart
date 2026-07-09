import 'package:flutter_test/flutter_test.dart';
import 'package:shoefit/models/cart_item_model.dart';
import 'package:shoefit/models/dashboard_analytics.dart';
import 'package:shoefit/models/order_model.dart';

void main() {
  test('analytics excludes cancelled orders from paid revenue', () {
    final now = DateTime(2026, 7, 9, 12);
    final orders = [
      _order(
        id: '1',
        total: 100,
        status: 'Processing',
        date: DateTime(2026, 7, 9),
      ),
      _order(
        id: '2',
        total: 200,
        status: 'Completed',
        date: DateTime(2026, 7, 8),
      ),
      _order(
        id: '3',
        total: 400,
        status: 'Cancelled',
        date: DateTime(2026, 7, 7),
      ),
      _order(
        id: '4',
        total: 150,
        status: 'Completed',
        date: DateTime(2026, 7, 1),
      ),
    ];

    final analytics = DashboardAnalytics.fromOrders(
      orders,
      range: AnalyticsRange.sevenDays,
      now: now,
    );

    expect(analytics.revenue, 300);
    expect(analytics.orderCount, 3);
    expect(analytics.averageOrderValue, 150);
    expect(analytics.revenueChange, 100);
    expect(analytics.unitCount, 2);
    expect(analytics.unitChange, 100);
    expect(analytics.cancellationRate, closeTo(33.33, 0.01));
    expect(analytics.statusCounts['Cancelled'], 1);
    expect(analytics.topProducts.single.quantity, 2);
    expect(analytics.topProducts.single.revenueShare, 100);
  });

  test('delivered orders require customer confirmation before completion', () {
    final delivered = _order(
      id: '10',
      total: 250,
      status: 'Delivered',
      date: DateTime(2026, 7, 9),
    );

    expect(delivered.canConfirmReceipt, isTrue);
    expect(delivered.isCompleted, isFalse);
    expect(delivered.statusStep, 3);

    final completed = delivered.copyWith(orderStatus: 'Completed');
    expect(completed.canConfirmReceipt, isFalse);
    expect(completed.isCompleted, isTrue);
    expect(completed.statusStep, 4);
  });
}

OrderModel _order({
  required String id,
  required double total,
  required String status,
  required DateTime date,
}) {
  return OrderModel(
    orderId: id,
    userId: 'user_$id',
    customerName: 'Customer $id',
    customerPhone: '0123456789',
    deliveryAddress: 'Kuala Lumpur',
    items: [
      CartItemModel(
        id: 'item_$id',
        shoeId: 'shoe_1',
        name: 'Velocity One',
        brand: 'Astra',
        imageUrl: '',
        selectedSize: 42,
        price: total,
        quantity: 1,
      ),
    ],
    subtotal: total,
    shippingFee: 0,
    totalPrice: total,
    paymentMethod: 'Demo card',
    paymentStatus: 'paid',
    stripePaymentId: '',
    orderStatus: status,
    orderDate: date,
  );
}
