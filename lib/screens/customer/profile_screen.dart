import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/screens/auth/login_screen.dart';
import 'package:shoefit/screens/customer/edit_profile_screen.dart';
import 'package:shoefit/screens/customer/favourites_screen.dart';
import 'package:shoefit/screens/customer/orders_screen.dart';
import 'package:shoefit/widgets/loading_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().signOut();
    if (!context.mounted) {
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
    final displayName = profile?.fullName.trim() ?? '';

    if (profile == null) {
      return const Scaffold(body: LoadingWidget(message: 'Loading profile...'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Text(
                      displayName.isEmpty
                          ? 'S'
                          : displayName.substring(0, 1).toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName.isEmpty ? 'ShoeFit User' : displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(profile.email),
                        const SizedBox(height: 4),
                        Text(
                          profile.phone.isEmpty
                              ? 'No phone saved'
                              : profile.phone,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileMenuTile(
            icon: Icons.receipt_long_outlined,
            title: 'My Orders',
            subtitle: 'Track your latest purchases',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
            },
          ),
          _ProfileMenuTile(
            icon: Icons.favorite_border_rounded,
            title: 'Favourites',
            subtitle: 'Saved shoes you love',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavouritesScreen()),
              );
            },
          ),
          _ProfileMenuTile(
            icon: Icons.edit_outlined,
            title: 'Edit Profile',
            subtitle: 'Update delivery and contact information',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
          ),
          _ProfileMenuTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            subtitle: 'Get support for setup and demo flows',
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Help Center'),
                  content: const Text(
                    'Use the demo card and make sure the ShoeFit API is reachable before checkout.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _ProfileMenuTile(
            icon: Icons.info_outline_rounded,
            title: 'About ShoeFit',
            subtitle: 'API-powered e-commerce demo app',
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'ShoeFit',
                applicationVersion: '1.0.0',
                applicationLegalese:
                    'Built with Flutter, Provider, and the ShoeFit REST API.',
              );
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}
