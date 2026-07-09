import 'dart:math' as math;

import 'package:intl/intl.dart';
import 'package:shoefit/models/order_model.dart';

enum AnalyticsRange {
  sevenDays('7 days', 7),
  thirtyDays('30 days', 30),
  ninetyDays('90 days', 90),
  allTime('All time', null);

  const AnalyticsRange(this.label, this.days);

  final String label;
  final int? days;
}

class AnalyticsBucket {
  const AnalyticsBucket({
    required this.label,
    required this.revenue,
    required this.orderCount,
  });

  final String label;
  final double revenue;
  final int orderCount;
}

class ProductPerformance {
  const ProductPerformance({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final int quantity;
  final double revenue;
}

class DashboardAnalytics {
  const DashboardAnalytics({
    required this.revenue,
    required this.orderCount,
    required this.averageOrderValue,
    required this.paidOrderCount,
    required this.activeCustomerCount,
    required this.fulfilmentRate,
    required this.revenueChange,
    required this.orderChange,
    required this.pendingOrderCount,
    required this.attentionOrderCount,
    required this.statusCounts,
    required this.buckets,
    required this.topProducts,
    required this.recentOrders,
  });

  final double revenue;
  final int orderCount;
  final double averageOrderValue;
  final int paidOrderCount;
  final int activeCustomerCount;
  final double fulfilmentRate;
  final double? revenueChange;
  final double? orderChange;
  final int pendingOrderCount;
  final int attentionOrderCount;
  final Map<String, int> statusCounts;
  final List<AnalyticsBucket> buckets;
  final List<ProductPerformance> topProducts;
  final List<OrderModel> recentOrders;

  factory DashboardAnalytics.fromOrders(
    List<OrderModel> allOrders, {
    required AnalyticsRange range,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final periodStart = _periodStart(allOrders, range, today);
    final periodOrders =
        allOrders
            .where((order) => !order.orderDate.isBefore(periodStart))
            .toList()
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

    final revenueOrders = periodOrders
        .where((order) => order.isPaid && !order.isCancelled)
        .toList();
    final revenue = revenueOrders.fold<double>(
      0,
      (total, order) => total + order.totalPrice,
    );
    final completed = periodOrders
        .where((order) => order.isCompleted || order.isDelivered)
        .length;

    final statusCounts = <String, int>{};
    for (final order in periodOrders) {
      statusCounts.update(
        order.orderStatus,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    final productMap = <String, ({int quantity, double revenue})>{};
    for (final order in revenueOrders) {
      for (final item in order.items) {
        final current = productMap[item.name];
        productMap[item.name] = (
          quantity: (current?.quantity ?? 0) + item.quantity,
          revenue: (current?.revenue ?? 0) + item.totalPrice,
        );
      }
    }
    final topProducts =
        productMap.entries
            .map(
              (entry) => ProductPerformance(
                name: entry.key,
                quantity: entry.value.quantity,
                revenue: entry.value.revenue,
              ),
            )
            .toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));

    double? revenueChange;
    double? orderChange;
    if (range.days != null) {
      final previousStart = periodStart.subtract(Duration(days: range.days!));
      final previousOrders = allOrders.where(
        (order) =>
            !order.orderDate.isBefore(previousStart) &&
            order.orderDate.isBefore(periodStart),
      );
      final previousList = previousOrders.toList();
      final previousRevenue = previousList
          .where((order) => order.isPaid && !order.isCancelled)
          .fold<double>(0, (total, order) => total + order.totalPrice);
      revenueChange = _percentageChange(revenue, previousRevenue);
      orderChange = _percentageChange(
        periodOrders.length.toDouble(),
        previousList.length.toDouble(),
      );
    }

    final activeCustomers = periodOrders.map((order) => order.userId).toSet();
    final attentionThreshold = today.subtract(const Duration(hours: 48));
    final attentionOrders = allOrders.where(
      (order) =>
          order.normalizedStatus == 'processing' &&
          order.orderDate.isBefore(attentionThreshold),
    );

    return DashboardAnalytics(
      revenue: revenue,
      orderCount: periodOrders.length,
      averageOrderValue: revenueOrders.isEmpty
          ? 0
          : revenue / revenueOrders.length,
      paidOrderCount: revenueOrders.length,
      activeCustomerCount: activeCustomers.length,
      fulfilmentRate: periodOrders.isEmpty
          ? 0
          : completed / periodOrders.length * 100,
      revenueChange: revenueChange,
      orderChange: orderChange,
      pendingOrderCount: allOrders.where((order) => order.isActive).length,
      attentionOrderCount: attentionOrders.length,
      statusCounts: statusCounts,
      buckets: _buildBuckets(periodOrders, periodStart, today),
      topProducts: topProducts.take(4).toList(),
      recentOrders: periodOrders.take(5).toList(),
    );
  }

  static DateTime _periodStart(
    List<OrderModel> orders,
    AnalyticsRange range,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    if (range.days != null) {
      return today.subtract(Duration(days: range.days! - 1));
    }
    if (orders.isEmpty) {
      return today;
    }
    final earliest = orders
        .map((order) => order.orderDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime(earliest.year, earliest.month, earliest.day);
  }

  static List<AnalyticsBucket> _buildBuckets(
    List<OrderModel> orders,
    DateTime start,
    DateTime now,
  ) {
    final lastDay = DateTime(now.year, now.month, now.day);
    final totalDays = math.max(1, lastDay.difference(start).inDays + 1);
    final bucketCount = math.min(7, totalDays);
    final bucketDays = (totalDays / bucketCount).ceil();
    final buckets = <AnalyticsBucket>[];

    for (var index = 0; index < bucketCount; index++) {
      final bucketStart = start.add(Duration(days: index * bucketDays));
      final calculatedEnd = bucketStart.add(Duration(days: bucketDays));
      final bucketEnd =
          calculatedEnd.isAfter(lastDay.add(const Duration(days: 1)))
          ? lastDay.add(const Duration(days: 1))
          : calculatedEnd;
      if (bucketStart.isAfter(lastDay)) {
        break;
      }
      final matching = orders.where(
        (order) =>
            !order.orderDate.isBefore(bucketStart) &&
            order.orderDate.isBefore(bucketEnd),
      );
      final matchingList = matching.toList();
      final revenue = matchingList
          .where((order) => order.isPaid && !order.isCancelled)
          .fold<double>(0, (total, order) => total + order.totalPrice);
      final label = bucketDays == 1
          ? DateFormat('E').format(bucketStart)
          : DateFormat('d MMM').format(bucketStart);
      buckets.add(
        AnalyticsBucket(
          label: label,
          revenue: revenue,
          orderCount: matchingList.length,
        ),
      );
    }
    return buckets;
  }

  static double? _percentageChange(double current, double previous) {
    if (previous == 0) {
      return current == 0 ? 0 : null;
    }
    return (current - previous) / previous * 100;
  }
}
