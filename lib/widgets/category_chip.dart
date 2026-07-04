import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.w700,
      ),
      avatar: isSelected
          ? const Icon(Icons.done_rounded, size: 18, color: Colors.white)
          : null,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}
