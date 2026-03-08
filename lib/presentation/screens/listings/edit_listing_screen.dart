import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:kigali_connect/presentation/widgets/listings/listing_form.dart';

class EditListingScreen extends StatelessWidget {
  const EditListingScreen({super.key, required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final initial = ListingFormData(
      name:          listing.name,
      category:      listing.category,
      address:       listing.address,
      contactNumber: listing.contactNumber,
      description:   listing.description,
      latitude:      listing.latitude,
      longitude:     listing.longitude,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Place')),
      body: BlocListener<ListingsBloc, ListingsState>(
        listener: (context, state) {
          if (state is ListingsActionSuccess) {
            Navigator.of(context).pop();
          } else if (state is ListingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: BlocBuilder<ListingsBloc, ListingsState>(
          builder: (context, state) {
            final isLoading = state is ListingsLoading;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.p16),
              child: ListingForm(
                initial: initial,
                submitLabel: 'Save Changes',
                isLoading: isLoading,
                onSubmit: (data) {
                  final updated = listing.copyWith(
                    name:          data.name,
                    category:      data.category,
                    address:       data.address,
                    contactNumber: data.contactNumber,
                    description:   data.description,
                    latitude:      data.latitude,
                    longitude:     data.longitude,
                    updatedAt:     DateTime.now(),
                  );
                  context.read<ListingsBloc>().add(ListingUpdated(updated));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
