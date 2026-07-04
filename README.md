# ShoeFit - Hosted PHP API Demo

ShoeFit is a Flutter shoe e-commerce app connected to a hosted Hostinger PHP API and MySQL database.

## Backend flow

```text
Flutter app -> https://astahoshi.xyz/api -> PHP API -> Hostinger MySQL
```

## Tech stack

- Flutter + Dart
- Provider state management
- Hostinger PHP API
- MySQL database
- Demo card checkout
- Public image URLs for products

## API base URL

```text
https://astahoshi.xyz/api
```

The app defaults to that hosted API in both debug and release builds.

## Core PHP endpoints

- `login.php`
- `register.php`
- `products.php`
- `product_detail.php`
- `cart_add.php`
- `cart_list.php`
- `cart_update.php`
- `cart_remove.php`
- `cart_clear.php`
- `favourites.php`
- `favourite_toggle.php`
- `favourite_status.php`
- `checkout.php`
- `orders.php`
- `order_detail.php`
- `profile.php`
- `profile_update.php`
- `admin_orders.php`
- `product_save.php`
- `product_delete.php`
- `order_status_update.php`
- `test.php`

## Run the app

```bash
flutter pub get
flutter run
```

You can still override the API base URL if needed:

```bash
flutter run --dart-define=API_BASE_URL=https://astahoshi.xyz/api
```

## Build a release APK

```bash
flutter clean
flutter pub get
flutter build apk --release
```

The generated APK will be at:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Notes

- Flutter does not connect directly to MySQL.
- Product images use public image URLs.
- API requests are sent as JSON and logged in the client for easier debugging.
