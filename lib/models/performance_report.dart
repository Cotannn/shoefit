import 'package:intl/intl.dart';
import 'package:shoefit/models/order_model.dart';

enum PerformanceInterval {
  weekly('Weekly'),
  monthly('Monthly'),
  yearly('Yearly');

  const PerformanceInterval(this.label);

  final String label;
}

class PerformancePeriod {
  const PerformancePeriod({
    required this.label,
    required this.start,
    required this.end,
    required this.revenue,
    required this.orderCount,
    required this.unitCount,
    required this.cancelledCount,
  });

  final String label;
  final DateTime start;
  final DateTime end;
  final double revenue;
  final int orderCount;
  final int unitCount;
  final int cancelledCount;

  double get averageOrderValue => orderCount == 0 ? 0 : revenue / orderCount;
}

class ReportProductPerformance {
  const ReportProductPerformance({
    required this.name,
    required this.revenue,
    required this.quantity,
    required this.revenueShare,
  });

  final String name;
  final double revenue;
  final int quantity;
  final double revenueShare;

  double get averageSellingPrice => quantity == 0 ? 0 : revenue / quantity;
}

class PerformanceReport {
  const PerformanceReport({
    required this.interval,
    required this.periods,
    required this.revenue,
    required this.orderCount,
    required this.unitCount,
    required this.averageOrderValue,
    required this.cancellationRate,
    required this.completedPeriodChange,
    required this.comparisonPeriod,
    required this.previousComparisonPeriod,
    required this.bestCompletedPeriod,
    required this.strongestGrowthPeriod,
    required this.strongestGrowth,
    required this.products,
  });

  final PerformanceInterval interval;
  final List<PerformancePeriod> periods;
  final double revenue;
  final int orderCount;
  final int unitCount;
  final double averageOrderValue;
  final double cancellationRate;
  final double? completedPeriodChange;
  final PerformancePeriod? comparisonPeriod;
  final PerformancePeriod? previousComparisonPeriod;
  final PerformancePeriod? bestCompletedPeriod;
  final PerformancePeriod? strongestGrowthPeriod;
  final double? strongestGrowth;
  final List<ReportProductPerformance> products;

  PerformancePeriod? get currentPeriod => periods.isEmpty ? null : periods.last;

  factory PerformanceReport.fromOrders(
    List<OrderModel> allOrders, {
    required PerformanceInterval interval,
    DateTime? now,
  }) {
    final reportDate = now ?? DateTime.now();
    final boundaries = _buildBoundaries(
      allOrders,
      interval: interval,
      now: reportDate,
    );
    final periods = <PerformancePeriod>[];

    for (var index = 0; index < boundaries.length - 1; index++) {
      final start = boundaries[index];
      final end = boundaries[index + 1];
      final matchingOrders = allOrders
          .where(
            (order) =>
                !order.orderDate.isBefore(start) &&
                order.orderDate.isBefore(end),
          )
          .toList();
      final revenueOrders = matchingOrders
          .where((order) => order.isPaid && !order.isCancelled)
          .toList();
      periods.add(
        PerformancePeriod(
          label: _periodLabel(start, interval),
          start: start,
          end: end,
          revenue: revenueOrders.fold<double>(
            0,
            (total, order) => total + order.totalPrice,
          ),
          orderCount: revenueOrders.length,
          unitCount: revenueOrders.fold<int>(
            0,
            (total, order) => total + order.itemCount,
          ),
          cancelledCount: matchingOrders
              .where((order) => order.isCancelled)
              .length,
        ),
      );
    }

    final windowStart = boundaries.first;
    final windowEnd = boundaries.last;
    final windowOrders = allOrders
        .where(
          (order) =>
              !order.orderDate.isBefore(windowStart) &&
              order.orderDate.isBefore(windowEnd),
        )
        .toList();
    final revenueOrders = windowOrders
        .where((order) => order.isPaid && !order.isCancelled)
        .toList();
    final revenue = revenueOrders.fold<double>(
      0,
      (total, order) => total + order.totalPrice,
    );
    final unitCount = revenueOrders.fold<int>(
      0,
      (total, order) => total + order.itemCount,
    );

    final completedPeriods = periods.length > 1
        ? periods.sublist(0, periods.length - 1)
        : <PerformancePeriod>[];
    final comparisonPeriod = completedPeriods.isEmpty
        ? null
        : completedPeriods.last;
    final previousComparisonPeriod = completedPeriods.length < 2
        ? null
        : completedPeriods[completedPeriods.length - 2];
    final completedPeriodChange =
        comparisonPeriod == null || previousComparisonPeriod == null
        ? null
        : percentageChange(
            comparisonPeriod.revenue,
            previousComparisonPeriod.revenue,
          );

    PerformancePeriod? bestCompletedPeriod;
    for (final period in completedPeriods) {
      if (bestCompletedPeriod == null ||
          period.revenue > bestCompletedPeriod.revenue) {
        bestCompletedPeriod = period;
      }
    }

    PerformancePeriod? strongestGrowthPeriod;
    double? strongestGrowth;
    for (var index = 1; index < completedPeriods.length; index++) {
      final growth = percentageChange(
        completedPeriods[index].revenue,
        completedPeriods[index - 1].revenue,
      );
      if (growth != null &&
          (strongestGrowth == null || growth > strongestGrowth)) {
        strongestGrowth = growth;
        strongestGrowthPeriod = completedPeriods[index];
      }
    }

    final productTotals = <String, ({double revenue, int quantity})>{};
    for (final order in revenueOrders) {
      for (final item in order.items) {
        final current = productTotals[item.name];
        productTotals[item.name] = (
          revenue: (current?.revenue ?? 0) + item.totalPrice,
          quantity: (current?.quantity ?? 0) + item.quantity,
        );
      }
    }
    final products =
        productTotals.entries
            .map(
              (entry) => ReportProductPerformance(
                name: entry.key,
                revenue: entry.value.revenue,
                quantity: entry.value.quantity,
                revenueShare: revenue == 0
                    ? 0
                    : entry.value.revenue / revenue * 100,
              ),
            )
            .toList()
          ..sort((a, b) => b.revenue.compareTo(a.revenue));

    final cancelledCount = windowOrders
        .where((order) => order.isCancelled)
        .length;
    return PerformanceReport(
      interval: interval,
      periods: periods,
      revenue: revenue,
      orderCount: revenueOrders.length,
      unitCount: unitCount,
      averageOrderValue: revenueOrders.isEmpty
          ? 0
          : revenue / revenueOrders.length,
      cancellationRate: windowOrders.isEmpty
          ? 0
          : cancelledCount / windowOrders.length * 100,
      completedPeriodChange: completedPeriodChange,
      comparisonPeriod: comparisonPeriod,
      previousComparisonPeriod: previousComparisonPeriod,
      bestCompletedPeriod: bestCompletedPeriod,
      strongestGrowthPeriod: strongestGrowthPeriod,
      strongestGrowth: strongestGrowth,
      products: products,
    );
  }

  static double? percentageChange(double current, double previous) {
    if (previous == 0) {
      return current == 0 ? 0 : null;
    }
    return (current - previous) / previous * 100;
  }

  static List<DateTime> _buildBoundaries(
    List<OrderModel> orders, {
    required PerformanceInterval interval,
    required DateTime now,
  }) {
    switch (interval) {
      case PerformanceInterval.weekly:
        final currentWeek = _startOfWeek(now);
        return List.generate(
          13,
          (index) => currentWeek.add(Duration(days: (index - 11) * 7)),
        );
      case PerformanceInterval.monthly:
        final currentMonth = DateTime(now.year, now.month);
        return List.generate(
          13,
          (index) => _addMonths(currentMonth, index - 11),
        );
      case PerformanceInterval.yearly:
        final earliestYear = orders.isEmpty
            ? now.year
            : orders
                  .map((order) => order.orderDate.year)
                  .reduce((a, b) => a < b ? a : b);
        final firstYear = earliestYear < now.year - 4
            ? earliestYear
            : now.year - 4;
        return List.generate(
          now.year - firstYear + 2,
          (index) => DateTime(firstYear + index),
        );
    }
  }

  static DateTime _startOfWeek(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - DateTime.monday));
  }

  static DateTime _addMonths(DateTime date, int months) {
    return DateTime(date.year, date.month + months);
  }

  static String _periodLabel(DateTime start, PerformanceInterval interval) {
    switch (interval) {
      case PerformanceInterval.weekly:
        return DateFormat('d MMM').format(start);
      case PerformanceInterval.monthly:
        return DateFormat('MMM yy').format(start);
      case PerformanceInterval.yearly:
        return DateFormat('yyyy').format(start);
    }
  }
}
