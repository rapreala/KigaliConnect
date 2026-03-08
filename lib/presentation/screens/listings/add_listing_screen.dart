import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:kigali_connect/presentation/widgets/listings/listing_form.dart';

class AddListingScreen extends StatelessWidget {
  const AddListingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Place')),
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
                submitLabel: 'Add Place',
                isLoading: isLoading,
                onSubmit: (data) {
                  final authState = context.read<AuthBloc>().state;
                  final uid = authState is AuthAuthenticated
                      ? authState.profile.uid
                      : '';
                  final now = DateTime.now();
                  final listing = Listing(
                    id: '',
                    name: data.name,
                    category: data.category,
                    address: data.address,
                    contactNumber: data.contactNumber,
                    description: data.description,
                    latitude: data.latitude,
                    longitude: data.longitude,
                    createdBy: uid,
                    createdAt: now,
                    updatedAt: now,
                  );
                  context.read<ListingsBloc>().add(ListingCreated(listing));
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
