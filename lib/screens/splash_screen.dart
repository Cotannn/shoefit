import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/screens/admin/admin_navigation.dart';
import 'package:shoefit/screens/auth/login_screen.dart';
import 'package:shoefit/screens/customer/customer_navigation.dart';
import 'package:shoefit/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.ensureInitialized();
    final preferences = await SharedPreferences.getInstance();
    final hasSeenOnboarding =
        preferences.getBool(AppConstants.onboardingKey) ?? false;

    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) {
      return;
    }

    final Widget destination;
    if (!hasSeenOnboarding) {
      destination = const OnboardingScreen();
    } else if (!authProvider.isAuthenticated) {
      destination = const LoginScreen();
    } else if (authProvider.isAdmin) {
      destination = const AdminNavigation();
    } else {
      destination = const CustomerNavigation();
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF08101F), Color(0xFF0B132B), Color(0xFF133B5C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.shopping_bag_rounded,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  AppConstants.appName,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.tagline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.74),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                const LinearProgressIndicator(
                  backgroundColor: Color(0x3322D3EE),
                  valueColor: AlwaysStoppedAnimation(Color(0xFF22D3EE)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
