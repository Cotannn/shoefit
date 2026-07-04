import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/providers/auth_provider.dart';
import 'package:shoefit/widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }

    final profile = context.read<AuthProvider>().profile;
    if (profile != null) {
      _fullNameController.text = profile.fullName;
      _phoneController.text = profile.phone;
      _addressController.text = profile.address;
      _cityController.text = profile.city;
      _stateController.text = profile.state;
      _postcodeController.text = profile.postcode;
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    try {
      await context.read<AuthProvider>().updateProfile(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postcode: _postcodeController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              CustomTextField(
                controller: _fullNameController,
                label: 'Full Name',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _phoneController,
                label: 'Phone Number',
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
              CustomTextField(
                controller: _cityController,
                label: 'City',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _stateController,
                label: 'State',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _postcodeController,
                label: 'Postcode',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: authProvider.isLoading ? null : _save,
                child: Text(
                  authProvider.isLoading ? 'Saving...' : 'Save Changes',
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
}
