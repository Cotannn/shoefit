import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/screens/admin/admin_orders_screen.dart';
import 'package:shoefit/screens/admin/admin_products_screen.dart';
import 'package:shoefit/screens/auth/login_screen.dart';
import 'package:shoefit/widgets/loading_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<Map<String, num>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = context.read<OrderProvider>().fetchDashboardStats();
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = context.read<OrderProvider>().fetchDashboardStats();
    });
    await _statsFuture;
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
    final authProvider = context.watch<AuthProvider>();
    final profile = authProvider.profile;

    if (profile == null) {
      return const Scaffold(body: LoadingWidget(message: 'Loading admin...'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, num>>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingWidget(
                message: 'Loading dashboard metrics...',
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Failed to load dashboard stats.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              );
            }

            final stats = snapshot.data ?? <String, num>{};
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${profile.fullName}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Manage products and keep customer orders moving.',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _StatCard(
                      title: 'Total products',
                      value: '${stats['totalProducts'] ?? 0}',
                    ),
                    _StatCard(
                      title: 'Total orders',
                      value: '${stats['totalOrders'] ?? 0}',
                    ),
                    _StatCard(
                      title: 'Total users',
                      value: '${stats['totalUsers'] ?? 0}',
                    ),
                    _StatCard(
                      title: 'Pending orders',
                      value: '${stats['pendingOrders'] ?? 0}',
                    ),
                    _StatCard(
                      title: 'Total sales',
                      value: AppFormatters.currency(
                        (stats['totalSales'] ?? 0).toDouble(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminProductsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Manage Products'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AdminOrdersScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.local_shipping_outlined),
                  label: const Text('Manage Orders'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width / 2 - 27,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
