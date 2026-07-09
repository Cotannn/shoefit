import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/performance_report.dart';
import 'package:shoefit/providers/order_provider.dart';

enum _ChartMetric {
  revenue('Revenue'),
  orders('Orders'),
  units('Units');

  const _ChartMetric(this.label);

  final String label;
}

class AdminPerformanceScreen extends StatefulWidget {
  const AdminPerformanceScreen({super.key});

  @override
  State<AdminPerformanceScreen> createState() => _AdminPerformanceScreenState();
}

class _AdminPerformanceScreenState extends State<AdminPerformanceScreen> {
  PerformanceInterval _interval = PerformanceInterval.monthly;
  _ChartMetric _chartMetric = _ChartMetric.revenue;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final report = PerformanceReport.fromOrders(
      provider.adminOrders,
      interval: _interval,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance report'),
        actions: [
          IconButton(
            tooltip: 'Refresh report',
            onPressed: provider.isAdminLoading
                ? null
                : provider.refreshAdminOrders,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: provider.refreshAdminOrders,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Historical performance',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Track sales momentum across completed periods and identify what is driving the result.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            _IntervalSelector(
              selected: _interval,
              onSelected: (interval) {
                setState(() => _interval = interval);
              },
            ),
            const SizedBox(height: 18),
            _ReportSummary(report: report),
            const SizedBox(height: 14),
            const _InProgressNotice(),
            const SizedBox(height: 24),
            _SectionTitle(
              title: '${_interval.label} trend',
              subtitle: _windowLabel(report),
            ),
            const SizedBox(height: 12),
            _MetricSelector(
              selected: _chartMetric,
              onSelected: (metric) => setState(() => _chartMetric = metric),
            ),
            const SizedBox(height: 10),
            _PerformanceChart(report: report, metric: _chartMetric),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Performance highlights',
              subtitle: 'Completed periods only',
            ),
            const SizedBox(height: 12),
            _Highlights(report: report),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Period breakdown',
              subtitle: 'Revenue, volume and order quality',
            ),
            const SizedBox(height: 12),
            _PeriodBreakdown(report: report),
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'Product contribution',
              subtitle: 'Across the displayed reporting window',
            ),
            const SizedBox(height: 12),
            _ProductContribution(products: report.products),
          ],
        ),
      ),
    );
  }
}

class _IntervalSelector extends StatelessWidget {
  const _IntervalSelector({required this.selected, required this.onSelected});

  final PerformanceInterval selected;
  final ValueChanged<PerformanceInterval> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: PerformanceInterval.values.map((interval) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: interval == PerformanceInterval.yearly ? 0 : 8,
            ),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(interval.label, textAlign: TextAlign.center),
              ),
              selected: selected == interval,
              onSelected: (_) => onSelected(interval),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  const _ReportSummary({required this.report});

  final PerformanceReport report;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (
        'Window revenue',
        AppFormatters.currency(report.revenue),
        Icons.payments_outlined,
        const Color(0xFF00897B),
      ),
      (
        'Paid orders',
        '${report.orderCount}',
        Icons.receipt_long_outlined,
        const Color(0xFF3765D8),
      ),
      (
        'Average order',
        AppFormatters.currency(report.averageOrderValue),
        Icons.shopping_bag_outlined,
        const Color(0xFF7B4DCC),
      ),
      (
        'Units sold',
        '${report.unitCount}',
        Icons.inventory_2_outlined,
        const Color(0xFFE17A22),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: width,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(metric.$3, color: metric.$4, size: 21),
                      const SizedBox(height: 12),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          metric.$2,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(metric.$1),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _InProgressNotice extends StatelessWidget {
  const _InProgressNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF3765D8), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The latest period is still in progress. Growth highlights compare the two most recent completed periods.',
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricSelector extends StatelessWidget {
  const _MetricSelector({required this.selected, required this.onSelected});

  final _ChartMetric selected;
  final ValueChanged<_ChartMetric> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _ChartMetric.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final metric = _ChartMetric.values[index];
          return ChoiceChip(
            label: Text(metric.label),
            selected: selected == metric,
            onSelected: (_) => onSelected(metric),
          );
        },
      ),
    );
  }
}

class _PerformanceChart extends StatelessWidget {
  const _PerformanceChart({required this.report, required this.metric});

  final PerformanceReport report;
  final _ChartMetric metric;

  @override
  Widget build(BuildContext context) {
    if (report.periods.isEmpty) {
      return const _EmptyCard(message: 'No historical data is available.');
    }
    final maximum = report.periods.fold<double>(
      0,
      (value, period) => math.max(value, _value(period)),
    );
    final chartWidth = math.max(
      MediaQuery.sizeOf(context).width - 72,
      report.periods.length * 58.0,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: report.periods.indexed.map((entry) {
                final index = entry.$1;
                final period = entry.$2;
                final value = _value(period);
                final fraction = maximum == 0
                    ? .02
                    : math.max(.02, value / maximum);
                final isCurrent = index == report.periods.length - 1;
                return Expanded(
                  child: Tooltip(
                    message: _tooltip(period),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: fraction,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? const Color(0xFF8FDAD8)
                                        : const Color(0xFF17BEBB),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            period.label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (isCurrent)
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Color(0xFF00897B),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            )
                          else
                            const SizedBox(height: 11),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  double _value(PerformancePeriod period) {
    switch (metric) {
      case _ChartMetric.revenue:
        return period.revenue;
      case _ChartMetric.orders:
        return period.orderCount.toDouble();
      case _ChartMetric.units:
        return period.unitCount.toDouble();
    }
  }

  String _tooltip(PerformancePeriod period) {
    switch (metric) {
      case _ChartMetric.revenue:
        return '${period.label}: ${AppFormatters.currency(period.revenue)}';
      case _ChartMetric.orders:
        return '${period.label}: ${period.orderCount} paid order(s)';
      case _ChartMetric.units:
        return '${period.label}: ${period.unitCount} unit(s)';
    }
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights({required this.report});

  final PerformanceReport report;

  @override
  Widget build(BuildContext context) {
    final best = report.bestCompletedPeriod;
    final topProduct = report.products.isEmpty ? null : report.products.first;
    final comparison = report.comparisonPeriod;
    final insights = [
      (
        Icons.trending_up_rounded,
        const Color(0xFF118B50),
        comparison == null
            ? 'More history needed'
            : '${comparison.label} ${_growthVerb(report.completedPeriodChange)}',
        comparison == null
            ? 'Two completed periods are required for a reliable growth comparison.'
            : '${_growthText(report.completedPeriodChange)} versus ${report.previousComparisonPeriod?.label}.',
      ),
      (
        Icons.emoji_events_outlined,
        const Color(0xFFE17A22),
        best == null
            ? 'No completed period yet'
            : '${best.label} performed best',
        best == null
            ? 'The report will identify a best period once one is completed.'
            : '${AppFormatters.currency(best.revenue)} from ${best.orderCount} paid order(s).',
      ),
      (
        Icons.workspace_premium_outlined,
        const Color(0xFF7B4DCC),
        topProduct == null
            ? 'No product leader yet'
            : '${topProduct.name} leads',
        topProduct == null
            ? 'Product contribution appears after paid sales are recorded.'
            : '${topProduct.revenueShare.toStringAsFixed(1)}% of window revenue from ${topProduct.quantity} unit(s).',
      ),
    ];

    return Card(
      child: Column(
        children: insights.indexed.map((entry) {
          final insight = entry.$2;
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                leading: CircleAvatar(
                  backgroundColor: insight.$2.withValues(alpha: .1),
                  child: Icon(insight.$1, color: insight.$2),
                ),
                title: Text(
                  insight.$3,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(insight.$4),
                ),
              ),
              if (entry.$1 < insights.length - 1)
                const Divider(height: 1, indent: 72),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodBreakdown extends StatelessWidget {
  const _PeriodBreakdown({required this.report});

  final PerformanceReport report;

  @override
  Widget build(BuildContext context) {
    if (report.periods.isEmpty) {
      return const _EmptyCard(message: 'No periods are available.');
    }
    final reversed = report.periods.reversed.toList();
    return Card(
      child: Column(
        children: reversed.indexed.map((entry) {
          final reversedIndex = entry.$1;
          final period = entry.$2;
          final originalIndex = report.periods.indexOf(period);
          final previous = originalIndex > 0
              ? report.periods[originalIndex - 1]
              : null;
          final growth = previous == null
              ? null
              : PerformanceReport.percentageChange(
                  period.revenue,
                  previous.revenue,
                );
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Text(
                                period.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (reversedIndex == 0) ...[
                                const SizedBox(width: 7),
                                const _LiveBadge(),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          AppFormatters.currency(period.revenue),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 8),
                        _GrowthBadge(value: growth),
                      ],
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(child: Text('${period.orderCount} orders')),
                        Expanded(
                          child: Text(
                            '${period.unitCount} units',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'AOV ${AppFormatters.currency(period.averageOrderValue)}',
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (reversedIndex < reversed.length - 1) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ProductContribution extends StatelessWidget {
  const _ProductContribution({required this.products});

  final List<ReportProductPerformance> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyCard(
        message: 'No paid product sales in this reporting window.',
      );
    }
    return Card(
      child: Column(
        children: products.take(10).toList().indexed.map((entry) {
          final index = entry.$1;
          final product = entry.$2;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${product.quantity} unit(s) • Avg ${AppFormatters.currency(product.averageSellingPrice)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AppFormatters.currency(product.revenue),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: (product.revenueShare / 100).clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEDF1F5),
                    color: index == 0
                        ? const Color(0xFF17BEBB)
                        : const Color(0xFF7C8DA5),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GrowthBadge extends StatelessWidget {
  const _GrowthBadge({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final numeric = value ?? 0;
    final positive = numeric >= 0;
    final color = positive ? const Color(0xFF118B50) : const Color(0xFFC43E4D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        value == null
            ? 'New'
            : '${positive ? '+' : ''}${numeric.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F5F3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Color(0xFF00897B),
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 3),
        Text(subtitle),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Center(child: Text(message, textAlign: TextAlign.center)),
      ),
    );
  }
}

String _windowLabel(PerformanceReport report) {
  if (report.periods.isEmpty) {
    return 'No reporting periods';
  }
  switch (report.interval) {
    case PerformanceInterval.weekly:
      return 'Last 12 weeks';
    case PerformanceInterval.monthly:
      return 'Last 12 months';
    case PerformanceInterval.yearly:
      return '${report.periods.first.label}–${report.periods.last.label}';
  }
}

String _growthVerb(double? growth) {
  if (growth == null) {
    return 'established a new baseline';
  }
  if (growth > 0) {
    return 'grew';
  }
  if (growth < 0) {
    return 'declined';
  }
  return 'held steady';
}

String _growthText(double? growth) {
  if (growth == null) {
    return 'New paid revenue';
  }
  return '${growth >= 0 ? '+' : ''}${growth.toStringAsFixed(1)}% revenue';
}
