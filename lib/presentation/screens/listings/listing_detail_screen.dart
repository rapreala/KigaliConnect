import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:kigali_connect/presentation/screens/listings/edit_listing_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ListingDetailScreen extends StatelessWidget {
  const ListingDetailScreen({
    super.key,
    required this.listing,
    this.canEdit = false,
  });

  // Initial listing used for first render; live updates come from the bloc.
  final Listing listing;
  final bool canEdit;

  Future<void> _openInMaps(Listing current) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${current.latitude},${current.longitude}',
    );
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _callPhone(BuildContext context, Listing current) async {
    final uri = Uri(scheme: 'tel', path: current.contactNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone dialler')),
      );
    }
  }

  void _confirmDelete(BuildContext context, Listing current) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('Remove "${current.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context
                  .read<ListingsBloc>()
                  .add(ListingDeleted(listing.id));
              Navigator.of(context).pop(); // back to list
            },
            child: Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ListingsBloc, ListingsState>(
      // Only rebuild when the specific listing changes or is removed.
      buildWhen: (prev, curr) => curr is ListingsLoaded,
      listenWhen: (prev, curr) => curr is ListingsLoaded,
      listener: (context, state) {
        if (state is ListingsLoaded) {
          final still = state.listings.any((l) => l.id == listing.id) ||
              state.filteredListings.any((l) => l.id == listing.id);
          if (!still && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        }
      },
      builder: (context, state) {
        // Use live listing from bloc if available, else fall back to initial.
        Listing current = listing;
        if (state is ListingsLoaded) {
          final live = [
            ...state.listings,
            ...state.filteredListings,
          ].cast<Listing?>().firstWhere(
                (l) => l?.id == listing.id,
                orElse: () => null,
              );
          if (live != null) current = live;
        }
        return _buildScaffold(context, current);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Listing current) {
    final cat = current.category;

    return Scaffold(
      appBar: AppBar(
        title: Text(current.name),
        actions: canEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditListingScreen(listing: current),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outlined),
                  onPressed: () => _confirmDelete(context, current),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Embedded map preview (250 px tall)
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(current.latitude, current.longitude),
                      zoom: 15,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId(current.id),
                        position: LatLng(current.latitude, current.longitude),
                        infoWindow: InfoWindow(title: current.name),
                      ),
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    scrollGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    tiltGesturesEnabled: false,
                  ),
                  Positioned(
                    bottom: AppSpacing.p12,
                    right: AppSpacing.p12,
                    child: FloatingActionButton.small(
                      heroTag: 'open_maps_${current.id}',
                      onPressed: () => _openInMaps(current),
                      tooltip: 'Open in Google Maps',
                      child: const Icon(Icons.open_in_new, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(AppSpacing.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + category badge row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          current.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.p8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.p8,
                          vertical: AppSpacing.p4,
                        ),
                        decoration: BoxDecoration(
                          color: cat.iconColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppSpacing.r8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(cat.iconData, size: 14, color: cat.iconColor),
                            const SizedBox(width: 4),
                            Text(
                              cat.displayName,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: cat.iconColor),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.p16),
                  const Divider(),
                  const SizedBox(height: AppSpacing.p12),

                  // Address
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    text: current.address,
                  ),
                  const SizedBox(height: AppSpacing.p12),

                  // Phone — tappable
                  GestureDetector(
                    onTap: () => _callPhone(context, current),
                    child: _InfoRow(
                      icon: Icons.phone_outlined,
                      text: current.contactNumber,
                      textColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.p12),

                  // Coordinates
                  _InfoRow(
                    icon: Icons.my_location_outlined,
                    text:
                        '${current.latitude.toStringAsFixed(4)}, ${current.longitude.toStringAsFixed(4)}',
                  ),

                  const SizedBox(height: AppSpacing.p16),
                  const Divider(),
                  const SizedBox(height: AppSpacing.p12),

                  Text('Description',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppSpacing.p8),
                  Text(
                    current.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),

                  const SizedBox(height: AppSpacing.p24),

                  // Navigate button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _openInMaps(current),
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.textColor,
  });

  final IconData icon;
  final String text;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
        const SizedBox(width: AppSpacing.p8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
          ),
        ),
      ],
    );
  }
}
