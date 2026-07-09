import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/models/dashboard_analytics.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/screens/admin/admin_orders_screen.dart';
import 'package:shoefit/screens/admin/admin_products_screen.dart';
import 'package:shoefit/screens/auth/login_screen.dart';
import 'package:shoefit/screens/customer/order_detail_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, num>> _statsFuture;
  AnalyticsRange _range = AnalyticsRange.thirtyDays;

  @override
  void initState() {
    super.initState();
    _statsFuture = context.read<OrderProvider>().fetchDashboardStats();
  }

  Future<void> _refresh() async {
    final provider = context.read<OrderProvider>();
    final statsFuture = provider.fetchDashboardStats();
    setState(() => _statsFuture = statsFuture);
    await Future.wait([statsFuture, provider.refreshAdminOrders()]);
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

  void _openOrders() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminOrdersScreen()));
  }

  void _openProducts() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const AdminProductsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final orderProvider = context.watch<OrderProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, num>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final baseStats = snapshot.data ?? const <String, num>{};
          final analytics = DashboardAnalytics.fromOrders(
            orderProvider.adminOrders,
            range: _range,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                _BusinessHeader(
                  name: profile?.fullName ?? 'Admin',
                  analytics: analytics,
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AnalyticsRange.values.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final range = AnalyticsRange.values[index];
                      return ChoiceChip(
                        label: Text(range.label),
                        selected: _range == range,
                        onSelected: (_) => setState(() => _range = range),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                _MetricsGrid(
                  analytics: analytics,
                  totalProducts: baseStats['totalProducts']?.toInt() ?? 0,
                  totalUsers: baseStats['totalUsers']?.toInt() ?? 0,
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 12),
                  const _InlineNotice(
                    icon: Icons.cloud_off_rounded,
                    message:
                        'Product and user totals are unavailable. Live order analytics are still shown.',
                  ),
                ],
                if (analytics.attentionOrderCount > 0) ...[
                  const SizedBox(height: 16),
                  _AttentionCard(
                    count: analytics.attentionOrderCount,
                    onTap: _openOrders,
                  ),
                ],
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Revenue performance',
                  subtitle: _range.label,
                ),
                const SizedBox(height: 12),
                _RevenueChart(buckets: analytics.buckets),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Order pipeline',
                  subtitle: '${analytics.pendingOrderCount} need attention',
                  actionLabel: 'Manage',
                  onAction: _openOrders,
                ),
                const SizedBox(height: 12),
                _StatusBreakdown(
                  counts: analytics.statusCounts,
                  total: analytics.orderCount,
                ),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Top products',
                  subtitle: 'Ranked by paid revenue',
                  actionLabel: 'Inventory',
                  onAction: _openProducts,
                ),
                const SizedBox(height: 12),
                _TopProducts(products: analytics.topProducts),
                const SizedBox(height: 24),
                _SectionHeader(
                  title: 'Recent orders',
                  subtitle: 'Latest customer activity',
                  actionLabel: 'View all',
                  onAction: _openOrders,
                ),
                const SizedBox(height: 12),
                _RecentOrders(orders: analytics.recentOrders),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openOrders,
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text('Orders'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _openProducts,
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('Products'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BusinessHeader extends StatelessWidget {
  const _BusinessHeader({required this.name, required this.analytics});

  final String name;
  final DashboardAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF19345A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${name.split(' ').first}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.currency(analytics.revenue),
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontSize: 34,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Paid revenue',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 10),
              _ChangePill(value: analytics.revenueChange),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.analytics,
    required this.totalProducts,
    required this.totalUsers,
  });

  final DashboardAnalytics analytics;
  final int totalProducts;
  final int totalUsers;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      _MetricData(
        label: 'Orders',
        value: '${analytics.orderCount}',
        icon: Icons.shopping_bag_outlined,
        color: const Color(0xFF3765D8),
        change: analytics.orderChange,
      ),
      _MetricData(
        label: 'Avg. order',
        value: AppFormatters.currency(analytics.averageOrderValue),
        icon: Icons.payments_outlined,
        color: const Color(0xFF00897B),
      ),
      _MetricData(
        label: 'Fulfilment',
        value: '${analytics.fulfilmentRate.toStringAsFixed(0)}%',
        icon: Icons.task_alt_rounded,
        color: const Color(0xFF7B4DCC),
      ),
      _MetricData(
        label: 'Customers',
        value: '${analytics.activeCustomerCount}',
        icon: Icons.people_alt_outlined,
        color: const Color(0xFFE17A22),
        helper: totalUsers > 0 ? '$totalUsers registered' : null,
      ),
      _MetricData(
        label: 'Paid orders',
        value: '${analytics.paidOrderCount}',
        icon: Icons.verified_outlined,
        color: const Color(0xFF118B50),
      ),
      _MetricData(
        label: 'Products',
        value: '$totalProducts',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFB14B6D),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 800
            ? 3
            : constraints.maxWidth >= 480
            ? 2
            : 2;
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics
              .map(
                (metric) => SizedBox(width: width, child: _MetricCard(metric)),
              )
              .toList(),
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.change,
    this.helper,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? change;
  final String? helper;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.metric);

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: metric.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(metric.icon, color: metric.color, size: 20),
                ),
                const Spacer(),
                if (metric.change != null)
                  _ChangePill(value: metric.change, compact: true),
              ],
            ),
            const SizedBox(height: 14),
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
            Text(metric.label),
            if (metric.helper != null) ...[
              const SizedBox(height: 3),
              Text(
                metric.helper!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.value, this.compact = false});

  final double? value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final hasComparison = value != null;
    final positive = (value ?? 0) >= 0;
    final color = positive ? const Color(0xFF118B50) : const Color(0xFFC43E4D);
    final text = hasComparison
        ? '${positive ? '+' : ''}${value!.toStringAsFixed(0)}%'
        : 'New';
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: compact
            ? color.withValues(alpha: .1)
            : Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: compact ? color : Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.buckets});

  final List<AnalyticsBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = buckets.fold<double>(
      0,
      (current, bucket) => math.max(current, bucket.revenue),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
        child: buckets.isEmpty
            ? const SizedBox(
                height: 150,
                child: Center(child: Text('No revenue in this period yet.')),
              )
            : SizedBox(
                height: 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: buckets.map((bucket) {
                    final fraction = maxRevenue == 0
                        ? 0.03
                        : math.max(.03, bucket.revenue / maxRevenue);
                    return Expanded(
                      child: Tooltip(
                        message:
                            '${AppFormatters.currency(bucket.revenue)} • ${bucket.orderCount} orders',
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Column(
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    heightFactor: fraction,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF17BEBB),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(8),
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 9),
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
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  const _StatusBreakdown({required this.counts, required this.total});

  final Map<String, int> counts;
  final int total;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(18),
        child: statuses.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('No orders in this period.')),
              )
            : Column(
                children: statuses.map((status) {
                  final count = counts[status] ?? 0;
                  final progress = total == 0 ? 0.0 : count / total;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _StatusDot(status: status),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                status,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text('$count'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 7,
                            backgroundColor: const Color(0xFFEDF1F5),
                            color: _statusColor(status),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.products});

  final List<ProductPerformance> products;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: products.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('Product sales will appear here.')),
            )
          : Column(
              children: products.indexed.map((entry) {
                final index = entry.$1;
                final product = entry.$2;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFE8EDF4),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  title: Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text('${product.quantity} pair(s) sold'),
                  trailing: Text(
                    AppFormatters.currency(product.revenue),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders({required this.orders});

  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Center(child: Text('No recent orders.')),
        ),
      );
    }
    return Card(
      child: Column(
        children: orders.map((order) {
          return ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      OrderDetailScreen(order: order, isAdminView: true),
                ),
              );
            },
            leading: const CircleAvatar(
              child: Icon(Icons.receipt_long_outlined, size: 20),
            ),
            title: Text(
              '${order.customerName} • #${order.orderId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${order.orderStatus} • ${AppFormatters.date(order.orderDate)}',
            ),
            trailing: Text(
              AppFormatters.currency(order.totalPrice),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          );
        }).toList(),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.schedule_rounded, color: Color(0xFFA65A00)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$count processing order(s) are older than 48 hours.',
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

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(message)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
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
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: _statusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
      return const Color(0xFF118B50);
    case 'delivered':
      return const Color(0xFF17A673);
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
