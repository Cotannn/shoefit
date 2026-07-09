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
    required this.previousRevenue,
    required this.orderCount,
  });

  final String label;
  final double revenue;
  final double previousRevenue;
  final int orderCount;
}

class ProductPerformance {
  const ProductPerformance({
    required this.name,
    required this.quantity,
    required this.revenue,
    required this.previousRevenue,
    required this.revenueShare,
  });

  final String name;
  final int quantity;
  final double revenue;
  final double previousRevenue;
  final double revenueShare;

  double? get revenueChange =>
      DashboardAnalytics.percentageChange(revenue, previousRevenue);
}

class DashboardAnalytics {
  const DashboardAnalytics({
    required this.revenue,
    required this.previousRevenue,
    required this.orderCount,
    required this.previousOrderCount,
    required this.averageOrderValue,
    required this.averageOrderValueChange,
    required this.unitCount,
    required this.unitChange,
    required this.paidOrderCount,
    required this.activeCustomerCount,
    required this.repeatCustomerRate,
    required this.cancellationRate,
    required this.cancellationRateChange,
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
  final double previousRevenue;
  final int orderCount;
  final int previousOrderCount;
  final double averageOrderValue;
  final double? averageOrderValueChange;
  final int unitCount;
  final double? unitChange;
  final int paidOrderCount;
  final int activeCustomerCount;
  final double repeatCustomerRate;
  final double cancellationRate;
  final double? cancellationRateChange;
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
    final averageOrderValue = revenueOrders.isEmpty
        ? 0.0
        : revenue / revenueOrders.length;
    final unitCount = revenueOrders.fold<int>(
      0,
      (total, order) => total + order.itemCount,
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

    var previousList = <OrderModel>[];
    var previousRevenue = 0.0;
    var previousAverageOrderValue = 0.0;
    var previousUnitCount = 0;
    if (range.days != null) {
      final previousStart = periodStart.subtract(Duration(days: range.days!));
      previousList = allOrders
          .where(
            (order) =>
                !order.orderDate.isBefore(previousStart) &&
                order.orderDate.isBefore(periodStart),
          )
          .toList();
      final previousRevenueOrders = previousList
          .where((order) => order.isPaid && !order.isCancelled)
          .toList();
      previousRevenue = previousRevenueOrders.fold<double>(
        0,
        (total, order) => total + order.totalPrice,
      );
      previousAverageOrderValue = previousRevenueOrders.isEmpty
          ? 0
          : previousRevenue / previousRevenueOrders.length;
      previousUnitCount = previousRevenueOrders.fold<int>(
        0,
        (total, order) => total + order.itemCount,
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
    final previousProductRevenue = <String, double>{};
    for (final order in previousList.where(
      (order) => order.isPaid && !order.isCancelled,
    )) {
      for (final item in order.items) {
        previousProductRevenue.update(
          item.name,
          (value) => value + item.totalPrice,
          ifAbsent: () => item.totalPrice,
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
                previousRevenue: previousProductRevenue[entry.key] ?? 0,
                revenueShare: revenue == 0
                    ? 0
                    : entry.value.revenue / revenue * 100,
              ),
            )
            .toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));

    double? revenueChange;
    double? orderChange;
    if (range.days != null) {
      revenueChange = _percentageChange(revenue, previousRevenue);
      orderChange = _percentageChange(
        periodOrders.length.toDouble(),
        previousList.length.toDouble(),
      );
    }

    final customerOrderCounts = <String, int>{};
    for (final order in revenueOrders) {
      customerOrderCounts.update(
        order.userId,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final activeCustomers = customerOrderCounts.keys.toSet();
    final repeatCustomers = customerOrderCounts.values
        .where((count) => count > 1)
        .length;
    final cancelledCount = periodOrders
        .where((order) => order.isCancelled)
        .length;
    final previousCancelledCount = previousList
        .where((order) => order.isCancelled)
        .length;
    final cancellationRate = periodOrders.isEmpty
        ? 0.0
        : cancelledCount / periodOrders.length * 100;
    final previousCancellationRate = previousList.isEmpty
        ? 0.0
        : previousCancelledCount / previousList.length * 100;
    final attentionThreshold = today.subtract(const Duration(hours: 48));
    final attentionOrders = allOrders.where(
      (order) =>
          order.normalizedStatus == 'processing' &&
          order.orderDate.isBefore(attentionThreshold),
    );

    return DashboardAnalytics(
      revenue: revenue,
      previousRevenue: previousRevenue,
      orderCount: periodOrders.length,
      previousOrderCount: previousList.length,
      averageOrderValue: averageOrderValue,
      averageOrderValueChange: range.days == null
          ? null
          : _percentageChange(averageOrderValue, previousAverageOrderValue),
      unitCount: unitCount,
      unitChange: range.days == null
          ? null
          : _percentageChange(
              unitCount.toDouble(),
              previousUnitCount.toDouble(),
            ),
      paidOrderCount: revenueOrders.length,
      activeCustomerCount: activeCustomers.length,
      repeatCustomerRate: activeCustomers.isEmpty
          ? 0
          : repeatCustomers / activeCustomers.length * 100,
      cancellationRate: cancellationRate,
      cancellationRateChange: range.days == null
          ? null
          : cancellationRate - previousCancellationRate,
      fulfilmentRate: periodOrders.isEmpty
          ? 0
          : completed / periodOrders.length * 100,
      revenueChange: revenueChange,
      orderChange: orderChange,
      pendingOrderCount: allOrders.where((order) => order.isActive).length,
      attentionOrderCount: attentionOrders.length,
      statusCounts: statusCounts,
      buckets: _buildBuckets(
        allOrders,
        periodOrders,
        periodStart,
        today,
        range.days,
      ),
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
    List<OrderModel> allOrders,
    List<OrderModel> orders,
    DateTime start,
    DateTime now,
    int? rangeDays,
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
      var previousRevenue = 0.0;
      if (rangeDays != null) {
        final previousStart = bucketStart.subtract(Duration(days: rangeDays));
        final previousEnd = bucketEnd.subtract(Duration(days: rangeDays));
        previousRevenue = allOrders
            .where(
              (order) =>
                  !order.orderDate.isBefore(previousStart) &&
                  order.orderDate.isBefore(previousEnd) &&
                  order.isPaid &&
                  !order.isCancelled,
            )
            .fold<double>(0, (total, order) => total + order.totalPrice);
      }
      final label = bucketDays == 1
          ? DateFormat('E').format(bucketStart)
          : DateFormat('d MMM').format(bucketStart);
      buckets.add(
        AnalyticsBucket(
          label: label,
          revenue: revenue,
          previousRevenue: previousRevenue,
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

  static double? percentageChange(double current, double previous) =>
      _percentageChange(current, previous);
}
