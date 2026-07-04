import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:shoefit/models/cart_item_model.dart';
import 'package:shoefit/models/order_model.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/widgets/order_card.dart';

void main() {
  test('cart item total price is calculated correctly', () {
    const item = CartItemModel(
      id: 'cart_1',
      shoeId: 'shoe_1',
      name: 'Velocity One',
      brand: 'Astra',
      imageUrl: 'https://example.com/image.jpg',
      selectedSize: 42,
      price: 399,
      quantity: 2,
    );

    expect(item.totalPrice, 798);
  });

  test('order item count sums all quantities', () {
    final order = OrderModel(
      orderId: 'order_1',
      userId: 'user_1',
      customerName: 'Test User',
      customerPhone: '0123456789',
      deliveryAddress: '123 Demo Street',
      items: [
        CartItemModel(
          id: 'cart_1',
          shoeId: 'shoe_1',
          name: 'Velocity One',
          brand: 'Astra',
          imageUrl: 'https://example.com/image.jpg',
          selectedSize: 42,
          price: 399,
          quantity: 2,
        ),
        CartItemModel(
          id: 'cart_2',
          shoeId: 'shoe_2',
          name: 'Court Pulse',
          brand: 'Northline',
          imageUrl: 'https://example.com/image-2.jpg',
          selectedSize: 43,
          price: 459,
          quantity: 1,
        ),
      ],
      subtotal: 1257,
      shippingFee: 15,
      totalPrice: 1272,
      paymentMethod: 'Stripe',
      paymentStatus: 'paid',
      stripePaymentId: 'pi_test',
      orderStatus: 'Processing',
      orderDate: DateTime(2026, 1, 1),
    );

    expect(order.itemCount, 3);
  });

  test('shoe model accepts string numbers from API rows', () {
    final shoe = ShoeModel.fromMap({
      'name': 'Velocity One',
      'brand': 'Astra',
      'category': 'Running',
      'price': '399.50',
      'rating': '4.8',
      'description': 'Daily running shoe',
      'imageUrl': 'https://example.com/image.jpg',
      'sizes': ['40', 41, '42'],
      'material': 'Mesh',
      'suitableUse': 'Road running',
      'stock': '12',
      'isFeatured': '1',
      'isNewArrival': 'true',
      'createdAt': '2026-01-01T00:00:00.000Z',
    }, id: 'shoe_1');

    expect(shoe.price, 399.50);
    expect(shoe.rating, 4.8);
    expect(shoe.stock, 12);
    expect(shoe.sizes, [40, 41, 42]);
    expect(shoe.isFeatured, isTrue);
    expect(shoe.isNewArrival, isTrue);
  });

  test('order model accepts short ids and string totals', () {
    final order = OrderModel.fromMap({
      'orderId': '6',
      'userId': 'user_1',
      'customerName': 'Test User',
      'customerPhone': '0123456789',
      'deliveryAddress': '123 Demo Street',
      'items': [
        {
          'shoeId': 1,
          'name': 'Velocity One',
          'brand': 'Astra',
          'imageUrl': 'https://example.com/image.jpg',
          'selectedSize': '42',
          'price': '399',
          'quantity': '2',
        },
      ],
      'subtotal': '798',
      'shippingFee': '15',
      'totalPrice': '813',
      'paymentMethod': '',
      'paymentStatus': '',
      'stripePaymentId': null,
      'orderStatus': '',
      'orderDate': '2026-01-01T00:00:00.000Z',
    }, id: '6');

    expect(order.orderId, '6');
    expect(order.itemCount, 2);
    expect(order.totalPrice, 813);
    expect(order.paymentMethod, 'Demo card');
    expect(order.paymentStatus, 'pending');
    expect(order.orderStatus, 'Processing');
  });

  testWidgets('order card supports short MySQL order ids', (tester) async {
    final order = OrderModel(
      orderId: '6',
      userId: 'user_1',
      customerName: 'Test User',
      customerPhone: '0123456789',
      deliveryAddress: '123 Demo Street',
      items: const [],
      subtotal: 0,
      shippingFee: 0,
      totalPrice: 0,
      paymentMethod: 'Demo card',
      paymentStatus: 'paid',
      stripePaymentId: '',
      orderStatus: 'Processing',
      orderDate: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OrderCard(order: order, onTap: () {}),
        ),
      ),
    );

    expect(find.text('#6'), findsOneWidget);
  });
}
