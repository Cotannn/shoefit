import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shoefit/config/app_constants.dart';
import 'package:shoefit/models/shoe_model.dart';
import 'package:shoefit/providers/product_provider.dart';
import 'package:shoefit/widgets/custom_text_field.dart';

class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({super.key, this.product});

  final ShoeModel? product;

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _priceController = TextEditingController();
  final _ratingController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sizesController = TextEditingController();
  final _materialController = TextEditingController();
  final _suitableUseController = TextEditingController();
  final _stockController = TextEditingController();

  String _selectedCategory = AppConstants.productCategories.first;
  bool _isFeatured = false;
  bool _isNewArrival = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameController.text = product.name;
      _brandController.text = product.brand;
      _imageUrlController.text = product.imageUrl;
      _priceController.text = product.price.toStringAsFixed(0);
      _ratingController.text = product.rating.toStringAsFixed(1);
      _descriptionController.text = product.description;
      _sizesController.text = product.sizes.join(', ');
      _materialController.text = product.material;
      _suitableUseController.text = product.suitableUse;
      _stockController.text = product.stock.toString();
      _selectedCategory = product.category;
      _isFeatured = product.isFeatured;
      _isNewArrival = product.isNewArrival;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _imageUrlController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    _sizesController.dispose();
    _materialController.dispose();
    _suitableUseController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_imageUrlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a public product image URL.'),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final productProvider = context.read<ProductProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final imageUrl = _imageUrlController.text.trim();

      final sizes = _sizesController.text
          .split(',')
          .map((item) => int.tryParse(item.trim()))
          .whereType<int>()
          .toList();

      final product = ShoeModel(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        brand: _brandController.text.trim(),
        category: _selectedCategory,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        rating: double.tryParse(_ratingController.text.trim()) ?? 0,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        sizes: sizes,
        material: _materialController.text.trim(),
        suitableUse: _suitableUseController.text.trim(),
        stock: int.tryParse(_stockController.text.trim()) ?? 0,
        isFeatured: _isFeatured,
        isNewArrival: _isNewArrival,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
      );

      if (widget.product == null) {
        await productProvider.addProduct(product);
      } else {
        await productProvider.updateProduct(product);
      }

      if (!mounted) {
        return;
      }

      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.product == null
                ? 'Product added successfully.'
                : 'Product updated successfully.',
          ),
        ),
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
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewImageUrl = _imageUrlController.text.trim();
    final hasPreviewUrl = previewImageUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This API stores image URLs. Paste a public image URL for each product.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: hasPreviewUrl
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          previewImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(20),
                                child: Text(
                                  'Could not load this image URL preview.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_rounded, size: 36),
                            SizedBox(height: 10),
                            Text('Paste a public image URL below'),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 18),
              CustomTextField(
                controller: _imageUrlController,
                label: 'Product image URL',
                hintText: 'https://images.unsplash.com/...',
                keyboardType: TextInputType.url,
                prefixIcon: const Icon(Icons.link_rounded),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isNotEmpty) {
                    final uri = trimmed.isEmpty ? null : Uri.tryParse(trimmed);
                    if (trimmed.isNotEmpty &&
                        (uri == null || !uri.hasScheme || !uri.hasAuthority)) {
                      return 'Enter a valid absolute image URL.';
                    }
                    return null;
                  }
                  return 'Image URL is required.';
                },
              ),
              const SizedBox(height: 18),
              CustomTextField(
                controller: _nameController,
                label: 'Shoe name',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _brandController,
                label: 'Brand',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: AppConstants.productCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _priceController,
                      label: 'Price',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _positiveNumberValidator,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _ratingController,
                      label: 'Rating',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _ratingValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _descriptionController,
                label: 'Description',
                maxLines: 4,
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _sizesController,
                label: 'Available sizes',
                hintText: '38, 39, 40, 41',
                validator: _sizesValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _materialController,
                label: 'Material',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _suitableUseController,
                label: 'Suitable use',
                validator: _requiredValidator,
              ),
              const SizedBox(height: 14),
              CustomTextField(
                controller: _stockController,
                label: 'Stock quantity',
                keyboardType: TextInputType.number,
                validator: _stockValidator,
              ),
              const SizedBox(height: 14),
              SwitchListTile.adaptive(
                value: _isFeatured,
                onChanged: (value) => setState(() => _isFeatured = value),
                title: const Text('Featured product'),
              ),
              SwitchListTile.adaptive(
                value: _isNewArrival,
                onChanged: (value) => setState(() => _isNewArrival = value),
                title: const Text('New arrival'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Product'),
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

  String? _positiveNumberValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) {
      return 'Enter a number greater than 0.';
    }
    return null;
  }

  String? _ratingValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final rating = double.tryParse(value?.trim() ?? '');
    if (rating == null || rating < 0 || rating > 5) {
      return 'Enter a rating between 0 and 5.';
    }
    return null;
  }

  String? _sizesValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final sizeParts = (value ?? '')
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    final sizes = sizeParts.map(int.tryParse).toList();
    if (sizes.isEmpty) {
      return 'Enter at least one size, separated by commas.';
    }
    if (sizes.any((size) => size == null)) {
      return 'Each size must be a whole number.';
    }
    if (sizes.whereType<int>().any((size) => size <= 0)) {
      return 'Sizes must be positive numbers.';
    }
    return null;
  }

  String? _stockValidator(String? value) {
    final requiredMessage = _requiredValidator(value);
    if (requiredMessage != null) {
      return requiredMessage;
    }

    final stock = int.tryParse(value?.trim() ?? '');
    if (stock == null || stock < 0) {
      return 'Enter a whole number of 0 or more.';
    }
    return null;
  }
}
