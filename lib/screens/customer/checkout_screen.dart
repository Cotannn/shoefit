import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_formatters.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/providers/cart_provider.dart';
import 'package:shoefit/screens/customer/order_success_screen.dart';
import 'package:shoefit/services/payment_service.dart';
import 'package:shoefit/widgets/custom_text_field.dart';
import 'package:shoefit/widgets/empty_state_widget.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _demoCardController = TextEditingController(
    text: '4242 4242 4242 4242',
  );
  final _demoExpiryController = TextEditingController(text: '12/30');
  final _demoCvcController = TextEditingController(text: '123');
  bool _didPrefill = false;
  bool _isPlacingOrder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefill) {
      return;
    }
    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      _nameController.text = profile.fullName;
      _phoneController.text = profile.phone;
      _addressController.text = profile.address;
      _cityController.text = profile.city;
      _stateController.text = profile.state;
      _postcodeController.text = profile.postcode;
    }
    _didPrefill = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _demoCardController.dispose();
    _demoExpiryController.dispose();
    _demoCvcController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final cartProvider = context.read<CartProvider>();
    final user = authProvider.profile;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }

    if (cartProvider.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer cannot checkout with empty cart.'),
        ),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);

    try {
      final paymentService = context.read<PaymentService>();
      final order = await paymentService.checkout(
        user: user,
        items: cartProvider.items,
        customerName: _nameController.text.trim(),
        customerPhone: _phoneController.text.trim(),
        deliveryAddress: [
          _addressController.text.trim(),
          _cityController.text.trim(),
          _stateController.text.trim(),
          _postcodeController.text.trim(),
        ].join(', '),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => OrderSuccessScreen(order: order)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPlacingOrder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();

    if (cartProvider.items.isEmpty) {
      return const Scaffold(
        body: EmptyStateWidget(
          title: 'No items to checkout',
          message: 'Add products to your cart before placing an order.',
          icon: Icons.shopping_bag_outlined,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                'Delivery details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _nameController,
                label: 'Full Name',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _addressController,
                label: 'Address',
                maxLines: 2,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _cityController,
                      label: 'City',
                      validator: _requiredValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _stateController,
                      label: 'State',
                      validator: _requiredValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _postcodeController,
                label: 'Postcode',
                keyboardType: TextInputType.number,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 26),
              Text(
                'Payment method',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.credit_card_rounded),
                  ),
                  title: const Text('Demo card payment'),
                  subtitle: const Text(
                    'Processed by the ShoeFit API. Saves the order, clears the cart, and updates stock.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _demoCardController,
                label: 'Demo Card Number',
                keyboardType: TextInputType.number,
                validator: _demoCardValidator,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _demoExpiryController,
                      label: 'Expiry',
                      hintText: 'MM/YY',
                      keyboardType: TextInputType.datetime,
                      validator: _requiredValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _demoCvcController,
                      label: 'CVC',
                      keyboardType: TextInputType.number,
                      validator: _demoCvcValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Order summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      ...cartProvider.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.name} - Size ${item.selectedSize}',
                                ),
                              ),
                              Text('x${item.quantity}'),
                              const SizedBox(width: 10),
                              Text(AppFormatters.currency(item.totalPrice)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 28),
                      _SummaryLine(
                        label: 'Subtotal',
                        value: AppFormatters.currency(cartProvider.subtotal),
                      ),
                      const SizedBox(height: 10),
                      _SummaryLine(
                        label: 'Shipping fee',
                        value: AppFormatters.currency(cartProvider.shippingFee),
                      ),
                      const SizedBox(height: 10),
                      _SummaryLine(
                        label: 'Total amount',
                        value: AppFormatters.currency(cartProvider.total),
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: _isPlacingOrder ? null : _placeOrder,
                child: Text(
                  _isPlacingOrder
                      ? 'Processing Payment...'
                      : 'Place Demo Order',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }
    return null;
  }

  String? _demoCardValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12) {
      return 'Enter a demo card number.';
    }
    return null;
  }

  String? _demoCvcValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 3) {
      return 'Enter a 3-digit CVC.';
    }
    return null;
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyLarge?.copyWith(
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
    );
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(value, style: style),
      ],
    );
  }
}
