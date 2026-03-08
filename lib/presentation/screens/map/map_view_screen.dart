import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:kigali_connect/presentation/screens/listings/listing_detail_screen.dart';
import 'package:kigali_connect/presentation/widgets/common/error_message.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';

class MapViewScreen extends StatefulWidget {
  const MapViewScreen({super.key});

  @override
  State<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends State<MapViewScreen> {
  GoogleMapController? _mapController;
  bool _mapLoadFailed = false;

  // Kigali city centre
  static const _kigaliCenter = LatLng(-1.9441, 30.0619);
  static const _initialZoom = 13.0;

  Set<Marker> _buildMarkers(
    List<Listing> listings,
    BuildContext context,
  ) {
    return listings.map((l) {
      return Marker(
        markerId: MarkerId(l.id),
        position: LatLng(l.latitude, l.longitude),
        infoWindow: InfoWindow(
          title: l.name,
          snippet: l.category.displayName,
          onTap: () {
            final authState = context.read<AuthBloc>().state;
            final canEdit = authState is AuthAuthenticated &&
                authState.profile.uid == l.createdBy;
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) =>
                  ListingDetailScreen(listing: l, canEdit: canEdit),
            ));
          },
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          _categoryHue(l),
        ),
      );
    }).toSet();
  }

  double _categoryHue(Listing l) {
    switch (l.category.name) {
      case 'hospital':
        return BitmapDescriptor.hueRed;
      case 'policeStation':
        return BitmapDescriptor.hueBlue;
      case 'library':
        return BitmapDescriptor.hueViolet;
      case 'restaurantCafe':
        return BitmapDescriptor.hueOrange;
      case 'park':
        return BitmapDescriptor.hueGreen;
      case 'touristAttraction':
        return BitmapDescriptor.hueYellow;
      case 'utilityOffice':
        return BitmapDescriptor.hueCyan;
      default:
        return BitmapDescriptor.hueRed;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map View')),
      body: BlocBuilder<ListingsBloc, ListingsState>(
        builder: (context, state) {
          if (state is ListingsInitial || state is ListingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ListingsError) {
            return ErrorMessage(
              message: state.message,
              onRetry: () => context
                  .read<ListingsBloc>()
                  .add(const ListingsSubscriptionRequested()),
            );
          }

          final listings =
              state is ListingsLoaded ? state.listings : <Listing>[];

          if (_mapLoadFailed) {
            return ErrorMessage(
              message: 'Map could not be loaded. '
                  'Check your Google Maps API key.',
              onRetry: () => setState(() => _mapLoadFailed = false),
            );
          }

          return GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _kigaliCenter,
              zoom: _initialZoom,
            ),
            markers: _buildMarkers(listings, context),
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (_) {},
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
