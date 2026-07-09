import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_theme.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/providers/cart_provider.dart';
import 'package:shoefit/providers/favourite_provider.dart';
import 'package:shoefit/providers/order_provider.dart';
import 'package:shoefit/providers/product_provider.dart';
import 'package:shoefit/screens/splash_screen.dart';
import 'package:shoefit/services/auth_service.dart';
import 'package:shoefit/services/cart_service.dart';
import 'package:shoefit/services/favourite_service.dart';
import 'package:shoefit/services/order_service.dart';
import 'package:shoefit/services/payment_service.dart';
import 'package:shoefit/services/product_service.dart';
import 'package:shoefit/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) => AppErrorFallback(details: details);
  runApp(const ShoeFitApp());
}

class AppErrorFallback extends StatelessWidget {
  const AppErrorFallback({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFF5F7FB),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 520),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 34),
                const SizedBox(height: 12),
                const Text(
                  'Something went wrong',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please refresh the page and try again. The app kept this screen safe instead of showing a debug error panel.',
                  style: TextStyle(fontSize: 15, height: 1.45),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 14),
                  Text(
                    details.exceptionAsString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShoeFitApp extends StatelessWidget {
  const ShoeFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => ProductService()),
        Provider(create: (_) => CartService()),
        Provider(create: (_) => FavouriteService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => PaymentService()),
        Provider(create: (_) => StorageService()),
        ChangeNotifierProvider(
          create: (context) =>
              AuthProvider(authService: context.read<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (context) =>
              ProductProvider(productService: context.read<ProductService>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (context) =>
              CartProvider(cartService: context.read<CartService>()),
          update: (context, authProvider, cartProvider) {
            final provider =
                cartProvider ??
                CartProvider(cartService: context.read<CartService>());
            provider.bindUser(
              authProvider.isAdmin ? null : authProvider.user?.uid,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, FavouriteProvider>(
          create: (context) => FavouriteProvider(
            favouriteService: context.read<FavouriteService>(),
          ),
          update: (context, authProvider, favouriteProvider) {
            final provider =
                favouriteProvider ??
                FavouriteProvider(
                  favouriteService: context.read<FavouriteService>(),
                );
            provider.bindUser(
              authProvider.isAdmin ? null : authProvider.user?.uid,
            );
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrderProvider>(
          create: (context) =>
              OrderProvider(orderService: context.read<OrderService>()),
          update: (context, authProvider, orderProvider) {
            final provider =
                orderProvider ??
                OrderProvider(orderService: context.read<OrderService>());
            provider.bindUser(
              authProvider.isAdmin ? null : authProvider.user?.uid,
            );
            provider.bindAdmin(authProvider.isAdmin);
            return provider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'ShoeFit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
