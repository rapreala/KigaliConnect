import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:kigali_connect/presentation/screens/listings/add_listing_screen.dart';
import 'package:kigali_connect/presentation/screens/listings/listing_detail_screen.dart';
import 'package:kigali_connect/presentation/widgets/common/empty_state.dart';
import 'package:kigali_connect/presentation/widgets/common/error_message.dart';
import 'package:kigali_connect/presentation/widgets/listings/listing_card.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  ListingsLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    final state = context.read<ListingsBloc>().state;
    if (state is ListingsInitial) {
      context.read<ListingsBloc>().add(const ListingsSubscriptionRequested());
    }
  }

  String? _currentUid(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) return authState.profile.uid;
    return null;
  }

  List<Listing> _myListings(ListingsLoaded loaded, String uid) =>
      loaded.allListings.where((l) => l.createdBy == uid).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: BlocConsumer<ListingsBloc, ListingsState>(
        listener: (context, state) {
          if (state is ListingsActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ListingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is ListingsLoading || state is ListingsInitial) {
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

          if (state is ListingsLoaded) _lastLoaded = state;
          final loaded = state is ListingsLoaded ? state : _lastLoaded;

          if (loaded == null) return const SizedBox.shrink();

          final uid = _currentUid(context);
          if (uid == null) {
            return const EmptyState(
              icon: Icons.person_off_outlined,
              title: 'Not signed in',
              subtitle: 'Sign in to manage your listings.',
            );
          }

          final items = _myListings(loaded, uid);

          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No listings yet',
              subtitle: 'Places you add will appear here.',
              actionLabel: 'Add a Place',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddListingScreen()),
              ),
            );
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final listing = items[index];
              return ListingCard(
                listing: listing,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListingDetailScreen(
                      listing: listing,
                      canEdit: true,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddListingScreen()),
        ),
        tooltip: 'Add Place',
        child: const Icon(Icons.add),
      ),
    );
  }
}
