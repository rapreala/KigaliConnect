import 'package:flutter/material.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/models/listing.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.listing,
    this.onTap,
  });

  final Listing listing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cat = listing.category;
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.p16,
        vertical: AppSpacing.p4,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.r12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.p16),
          child: Row(
            children: [
              // Category icon badge
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cat.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.r12),
                ),
                child: Icon(cat.iconData, color: cat.iconColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.p12),
              // Name + address
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      listing.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.p4),
                    // Category chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.p8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: cat.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppSpacing.r8),
                      ),
                      child: Text(
                        cat.displayName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cat.iconColor,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.p8),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
