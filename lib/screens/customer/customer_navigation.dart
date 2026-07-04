import 'package:flutter/material.dart';
import 'package:shoefit/screens/customer/cart_screen.dart';
import 'package:shoefit/screens/customer/catalogue_screen.dart';
import 'package:shoefit/screens/customer/home_screen.dart';
import 'package:shoefit/screens/customer/orders_screen.dart';
import 'package:shoefit/screens/customer/profile_screen.dart';

class CustomerNavigation extends StatefulWidget {
  const CustomerNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<CustomerNavigation> createState() => _CustomerNavigationState();
}

class _CustomerNavigationState extends State<CustomerNavigation> {
  late int _currentIndex = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final screens = <Widget>[
      const HomeScreen(),
      const CatalogueScreen(),
      const CartScreen(),
      const OrdersScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (value) => setState(() => _currentIndex = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Catalogue',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart_rounded),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
