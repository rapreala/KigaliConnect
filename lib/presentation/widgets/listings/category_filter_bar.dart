import 'package:flutter/material.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/domain/models/enums.dart';

class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PlaceCategory? selected;
  final void Function(PlaceCategory?) onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.p16),
        children: [
          // "All" chip
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.p8),
            child: FilterChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          ...PlaceCategory.values.map((cat) {
            final isSelected = selected == cat;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.p8),
              child: FilterChip(
                avatar: Icon(cat.iconData,
                    size: 16,
                    color: isSelected ? AppColors.background : cat.iconColor),
                label: Text(cat.displayName),
                selected: isSelected,
                onSelected: (_) => onSelected(isSelected ? null : cat),
              ),
            );
          }),
        ],
      ),
    );
  }
}
