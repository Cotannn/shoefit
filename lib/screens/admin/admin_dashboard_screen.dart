import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/dashboard_analytics.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/screens/admin/admin_orders_screen.dart';
import 'package:shoefit/screens/admin/admin_products_screen.dart';
import 'package:shoefit/screens/auth/login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.onNavigate});

  final ValueChanged<int>? onNavigate;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AnalyticsRange _range = AnalyticsRange.thirtyDays;

  Future<void> _refresh() {
    return context.read<OrderProvider>().refreshAdminOrders();
  }

  void _openOrders() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(1);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
  }

  void _openProducts() {
    if (widget.onNavigate != null) {
      widget.onNavigate!(2);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminProductsScreen()));
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final provider = context.watch<OrderProvider>();
    final analytics = DashboardAnalytics.fromOrders(
      provider.adminOrders,
      range: _range,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh data',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (widget.onNavigate == null)
            IconButton(
              tooltip: 'Sign out',
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _RevenueHero(
              name: profile?.fullName ?? 'Admin',
              analytics: analytics,
              range: _range,
            ),
            const SizedBox(height: 16),
            _RangeSelector(
              selected: _range,
              onSelected: (range) => setState(() => _range = range),
            ),
            const SizedBox(height: 18),
            _KpiGrid(analytics: analytics),
            if (analytics.attentionOrderCount > 0) ...[
              const SizedBox(height: 14),
              _AttentionCard(
                count: analytics.attentionOrderCount,
                onTap: _openOrders,
              ),
            ],
            const SizedBox(height: 24),
            const _SectionTitle(
              title: 'What moved the business',
              subtitle: 'Signals worth acting on',
            ),
            const SizedBox(height: 12),
            _BusinessInsights(analytics: analytics, range: _range),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Revenue trend',
              subtitle: _range.days == null
                  ? 'Paid sales over time'
                  : 'Current period compared with the previous period',
            ),
            const SizedBox(height: 12),
            _RevenueComparisonChart(
              buckets: analytics.buckets,
              showComparison: _range.days != null,
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Product momentum',
              subtitle: 'Revenue contribution and sales velocity',
              action: 'Inventory',
              onAction: _openProducts,
            ),
            const SizedBox(height: 12),
            _ProductMomentum(
              products: analytics.topProducts,
              showComparison: _range.days != null,
            ),
            const SizedBox(height: 24),
            _SectionTitle(
              title: 'Operations health',
              subtitle: '${analytics.pendingOrderCount} open order(s)',
              action: 'Manage',
              onAction: _openOrders,
            ),
            const SizedBox(height: 12),
            _OperationsSummary(
              counts: analytics.statusCounts,
              total: analytics.orderCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({
    required this.name,
    required this.analytics,
    required this.range,
  });

  final String name;
  final DashboardAnalytics analytics;
  final AnalyticsRange range;

  @override
  Widget build(BuildContext context) {
    final difference = analytics.revenue - analytics.previousRevenue;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF173D5E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, ${name.split(' ').first}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'PAID REVENUE',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppFormatters.currency(analytics.revenue),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 34,
            ),
          ),
          if (range.days != null) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                _DeltaBadge(value: analytics.revenueChange, onDark: true),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    '${difference >= 0 ? '+' : '-'}${AppFormatters.currency(difference.abs())} vs previous ${range.label}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 15),
          const Text(
            'Sales revenue before product costs and operating expenses.',
            style: TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selected, required this.onSelected});

  final AnalyticsRange selected;
  final ValueChanged<AnalyticsRange> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: AnalyticsRange.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final range = AnalyticsRange.values[index];
          return ChoiceChip(
            label: Text(range.label),
            selected: selected == range,
            onSelected: (_) => onSelected(range),
          );
        },
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.analytics});

  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _Metric(
        label: 'Orders',
        value: '${analytics.orderCount}',
        helper: '${analytics.previousOrderCount} previous',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF3765D8),
        change: analytics.orderChange,
      ),
      _Metric(
        label: 'Avg. order',
        value: AppFormatters.currency(analytics.averageOrderValue),
        helper: 'Revenue per paid order',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF00897B),
        change: analytics.averageOrderValueChange,
      ),
      _Metric(
        label: 'Units sold',
        value: '${analytics.unitCount}',
        helper: 'Paid, non-cancelled',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFF7B4DCC),
        change: analytics.unitChange,
      ),
      _Metric(
        label: 'Cancelled',
        value: '${analytics.cancellationRate.toStringAsFixed(1)}%',
        helper: 'Share of period orders',
        icon: Icons.block_outlined,
        color: const Color(0xFFC43E4D),
        change: analytics.cancellationRateChange,
        changeUnit: 'pp',
        positiveIsGood: false,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _MetricCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
    this.change,
    this.changeUnit = '%',
    this.positiveIsGood = true,
  });

  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;
  final double? change;
  final String changeUnit;
  final bool positiveIsGood;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _Metric metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 19),
                ),
                const Spacer(),
                if (metric.change != null)
                  _DeltaBadge(
                    value: metric.change,
                    unit: metric.changeUnit,
                    positiveIsGood: metric.positiveIsGood,
                    compact: true,
                  ),
              ],
            ),
            const SizedBox(height: 13),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                metric.value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              metric.label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 3),
            Text(
              metric.helper,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessInsights extends StatelessWidget {
  const _BusinessInsights({required this.analytics, required this.range});

  final DashboardAnalytics analytics;
  final AnalyticsRange range;

  @override
  Widget build(BuildContext context) {
    if (analytics.orderCount == 0) {
      return const _EmptyCard(
        message: 'No orders in this period. Choose a longer date range.',
      );
    }

    final topProduct = analytics.topProducts.firstOrNull;
    final revenueChange = analytics.revenueChange;
    final revenueDirection = (revenueChange ?? 0) >= 0 ? 'grew' : 'fell';
    final insights = <_Insight>[
      _Insight(
        icon: revenueDirection == 'grew'
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded,
        color: revenueDirection == 'grew'
            ? const Color(0xFF118B50)
            : const Color(0xFFC43E4D),
        title: range.days == null
            ? 'Revenue baseline established'
            : 'Revenue $revenueDirection ${revenueChange?.abs().toStringAsFixed(0) ?? '—'}%',
        message: range.days == null
            ? 'Select a fixed period to compare performance with the preceding period.'
            : '${AppFormatters.currency((analytics.revenue - analytics.previousRevenue).abs())} ${revenueDirection == 'grew' ? 'more' : 'less'} paid revenue than the previous ${range.label}.',
      ),
      if (topProduct != null)
        _Insight(
          icon: Icons.workspace_premium_outlined,
          color: const Color(0xFF7B4DCC),
          title: '${topProduct.name} leads sales',
          message:
              '${topProduct.revenueShare.toStringAsFixed(0)}% of revenue and ${topProduct.quantity} unit(s) sold in this period.',
        ),
      _Insight(
        icon: Icons.people_alt_outlined,
        color: const Color(0xFF3765D8),
        title:
            '${analytics.repeatCustomerRate.toStringAsFixed(0)}% repeat customers',
        message:
            '${analytics.activeCustomerCount} paying customer(s); repeat rate counts customers with multiple paid orders in this period.',
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
                  backgroundColor: insight.color.withValues(alpha: .11),
                  child: Icon(insight.icon, color: insight.color, size: 21),
                ),
                title: Text(
                  insight.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(insight.message),
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

class _Insight {
  const _Insight({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
}

class _RevenueComparisonChart extends StatelessWidget {
  const _RevenueComparisonChart({
    required this.buckets,
    required this.showComparison,
  });

  final List<AnalyticsBucket> buckets;
  final bool showComparison;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const _EmptyCard(message: 'No revenue data in this period.');
    }
    final maxRevenue = buckets.fold<double>(
      0,
      (maximum, bucket) =>
          math.max(maximum, math.max(bucket.revenue, bucket.previousRevenue)),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
        child: Column(
          children: [
            if (showComparison) ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _Legend(color: Color(0xFF17BEBB), label: 'Current'),
                  SizedBox(width: 14),
                  _Legend(color: Color(0xFFD7DEE7), label: 'Previous'),
                ],
              ),
              const SizedBox(height: 15),
            ],
            SizedBox(
              height: 190,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: buckets.map((bucket) {
                  final currentFraction = maxRevenue == 0
                      ? .02
                      : math.max(.02, bucket.revenue / maxRevenue);
                  final previousFraction = maxRevenue == 0
                      ? .02
                      : math.max(.02, bucket.previousRevenue / maxRevenue);
                  return Expanded(
                    child: Tooltip(
                      message: showComparison
                          ? '${AppFormatters.currency(bucket.revenue)} current\n${AppFormatters.currency(bucket.previousRevenue)} previous'
                          : '${AppFormatters.currency(bucket.revenue)} • ${bucket.orderCount} order(s)',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (showComparison)
                                    Expanded(
                                      child: FractionallySizedBox(
                                        heightFactor: previousFraction,
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFD7DEE7),
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (showComparison) const SizedBox(width: 2),
                                  Expanded(
                                    child: FractionallySizedBox(
                                      heightFactor: currentFraction,
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF17BEBB),
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(6),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bucket.label,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ProductMomentum extends StatelessWidget {
  const _ProductMomentum({
    required this.products,
    required this.showComparison,
  });

  final List<ProductPerformance> products;
  final bool showComparison;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const _EmptyCard(
        message: 'Product performance appears after paid orders are recorded.',
      );
    }
    return Card(
      child: Column(
        children: products.indexed.map((entry) {
          final index = entry.$1;
          final product = entry.$2;
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFE8EDF4),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 11),
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
                            '${product.quantity} unit(s) • ${product.revenueShare.toStringAsFixed(0)}% of revenue',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppFormatters.currency(product.revenue),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (showComparison)
                          _DeltaBadge(
                            value: product.revenueChange,
                            compact: true,
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 11),
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
                if (index < products.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(top: 14),
                    child: Divider(height: 1),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OperationsSummary extends StatelessWidget {
  const _OperationsSummary({required this.counts, required this.total});

  final Map<String, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const _EmptyCard(message: 'No orders in this period.');
    }
    final statuses = [
      ...AppConstants.orderStatuses.where(
        (status) => counts.containsKey(status),
      ),
      ...counts.keys.where(
        (status) => !AppConstants.orderStatuses.contains(status),
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 9,
          runSpacing: 9,
          children: statuses.map((status) {
            final count = counts[status] ?? 0;
            final color = _statusColor(status);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '$status  $count',
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({
    required this.value,
    this.unit = '%',
    this.positiveIsGood = true,
    this.onDark = false,
    this.compact = false,
  });

  final double? value;
  final String unit;
  final bool positiveIsGood;
  final bool onDark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final numericValue = value ?? 0;
    final isGood = positiveIsGood ? numericValue >= 0 : numericValue <= 0;
    final color = isGood ? const Color(0xFF118B50) : const Color(0xFFC43E4D);
    final text = value == null
        ? 'New'
        : '${numericValue >= 0 ? '+' : ''}${numericValue.toStringAsFixed(unit == 'pp' ? 1 : 0)}$unit';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: .14)
            : color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: onDark ? Colors.white : color,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF4DE),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded, color: Color(0xFFA65A00)),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  '$count processing order(s) are older than 48 hours',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 3),
              Text(subtitle),
            ],
          ),
        ),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!)),
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

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return const Color(0xFF118B50);
    case 'delivered':
      return const Color(0xFF168A73);
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
