import 'package:flutter_test/flutter_test.dart';
import 'package:shoefit/models/cart_item_model.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/models/performance_report.dart';

void main() {
  test('monthly report compares the latest completed months', () {
    final report = PerformanceReport.fromOrders(
      [
        _order('may', 100, DateTime(2026, 5, 15)),
        _order('jun', 200, DateTime(2026, 6, 15)),
        _order('jul', 300, DateTime(2026, 7, 8)),
        _order('cancelled', 500, DateTime(2026, 7, 7), status: 'Cancelled'),
      ],
      interval: PerformanceInterval.monthly,
      now: DateTime(2026, 7, 9),
    );

    expect(report.periods, hasLength(12));
    expect(report.currentPeriod?.label, 'Jul 26');
    expect(report.comparisonPeriod?.label, 'Jun 26');
    expect(report.previousComparisonPeriod?.label, 'May 26');
    expect(report.completedPeriodChange, 100);
    expect(report.revenue, 600);
    expect(report.orderCount, 3);
    expect(report.cancellationRate, 25);
    expect(report.bestCompletedPeriod?.label, 'Jun 26');
    expect(report.products.single.revenueShare, 100);
  });

  test('weekly report excludes the live week from growth comparison', () {
    final report = PerformanceReport.fromOrders(
      [
        _order('older', 100, DateTime(2026, 6, 24)),
        _order('last', 150, DateTime(2026, 7, 1)),
        _order('live', 500, DateTime(2026, 7, 8)),
      ],
      interval: PerformanceInterval.weekly,
      now: DateTime(2026, 7, 9),
    );

    expect(report.currentPeriod?.label, '6 Jul');
    expect(report.comparisonPeriod?.label, '29 Jun');
    expect(report.previousComparisonPeriod?.label, '22 Jun');
    expect(report.completedPeriodChange, 50);
  });

  test('yearly report includes a multi-year baseline', () {
    final report = PerformanceReport.fromOrders(
      [
        _order('2024', 100, DateTime(2024, 3, 1)),
        _order('2025', 200, DateTime(2025, 3, 1)),
        _order('2026', 300, DateTime(2026, 3, 1)),
      ],
      interval: PerformanceInterval.yearly,
      now: DateTime(2026, 7, 9),
    );

    expect(report.periods.first.label, '2022');
    expect(report.currentPeriod?.label, '2026');
    expect(report.comparisonPeriod?.label, '2025');
    expect(report.previousComparisonPeriod?.label, '2024');
    expect(report.completedPeriodChange, 100);
  });
}

OrderModel _order(
  String id,
  double total,
  DateTime date, {
  String status = 'Completed',
}) {
  return OrderModel(
    orderId: id,
    userId: 'user_$id',
    customerName: 'Customer',
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
