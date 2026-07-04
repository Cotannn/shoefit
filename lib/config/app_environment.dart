import 'package:flutter/foundation.dart';

class AppEnvironment {
  static const String _localApiBaseUrl = 'https://astahoshi.xyz/api';
  static const String _productionApiBaseUrl = 'https://astahoshi.xyz/api';

  static String get apiBaseUrl {
    const configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
    final trimmedBaseUrl = configuredBaseUrl.trim();
    if (trimmedBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(trimmedBaseUrl);
    }

    if (kReleaseMode) {
      return _normalizeBaseUrl(_productionApiBaseUrl);
    }

    return _normalizeBaseUrl(_localApiBaseUrl);
  }

  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  static const String stripeMerchantIdentifier = String.fromEnvironment(
    'STRIPE_MERCHANT_IDENTIFIER',
    defaultValue: 'merchant.com.example.shoefit',
  );
  static const String functionsRegion = String.fromEnvironment(
    'FUNCTIONS_REGION',
    defaultValue: 'us-central1',
  );
  static const String adminEmails = String.fromEnvironment(
    'ADMIN_EMAILS',
    defaultValue: 'aniq@mail.com',
  );
  static const double shippingFee = 15.0;
  static const String currencyCode = 'myr';
  static const String currencySymbol = 'RM ';

  static bool get isStripeConfigured => stripePublishableKey.startsWith('pk_');

  static String _normalizeBaseUrl(String value) =>
      value.replaceFirst(RegExp(r'/+$'), '');

  static bool isAdminEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return false;
    }

    final normalizedEmail = email.trim().toLowerCase();
    return adminEmails
        .split(',')
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .contains(normalizedEmail);
  }
}
