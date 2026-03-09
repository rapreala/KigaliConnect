import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:kigali_connect/presentation/blocs/listings/listings_bloc.dart';
import 'package:kigali_connect/presentation/screens/listings/add_listing_screen.dart';
import 'package:kigali_connect/presentation/screens/listings/listing_detail_screen.dart';
import 'package:kigali_connect/presentation/widgets/common/empty_state.dart';
import 'package:kigali_connect/presentation/widgets/common/error_message.dart';
import 'package:kigali_connect/presentation/widgets/listings/category_filter_bar.dart';
import 'package:kigali_connect/presentation/widgets/listings/listing_card.dart';

class ListingsScreen extends StatefulWidget {
  const ListingsScreen({super.key});

  @override
  State<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends State<ListingsScreen> {
  final _searchController = TextEditingController();
  // Cache the last loaded state so the list stays visible during transient
  // states like ListingsActionSuccess (which carries no list data).
  ListingsLoaded? _lastLoaded;

  @override
  void initState() {
    super.initState();
    context
        .read<ListingsBloc>()
        .add(const ListingsSubscriptionRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildEmptyState(BuildContext context, ListingsLoaded loaded) {
    final hasSearch = loaded.searchQuery.isNotEmpty;
    final hasCategory = loaded.selectedCategory != null;

    if (hasSearch) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: 'No results for "${loaded.searchQuery}"',
        subtitle: 'Try a different keyword or clear the search',
      );
    }

    if (hasCategory) {
      final catName = loaded.selectedCategory!.displayName;
      return EmptyState(
        icon: loaded.selectedCategory!.iconData,
        title: 'No $catName places yet',
        subtitle: 'Be the first to add a $catName spot in Kigali!',
        actionLabel: 'Add $catName Place',
        onAction: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AddListingScreen()),
        ),
      );
    }

    return EmptyState(
      icon: Icons.location_off_outlined,
      title: 'No places yet',
      subtitle: 'Start building the Kigali directory — add the first place!',
      actionLabel: 'Add a Place',
      onAction: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddListingScreen()),
      ),
    );
  }

  bool _canEdit(BuildContext context, String createdBy) {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      return authState.profile.uid == createdBy;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.p16, 0, AppSpacing.p16, AppSpacing.p8,
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (q) =>
                  context.read<ListingsBloc>().add(ListingsSearchChanged(q)),
              decoration: InputDecoration(
                hintText: 'Search places…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context
                              .read<ListingsBloc>()
                              .add(const ListingsSearchChanged(''));
                        },
                      )
                    : null,
                isDense: true,
              ),
            ),
          ),
        ),
      ),
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

          if (loaded != null) {
            final items = loaded.searchQuery.isEmpty
                ? loaded.listings
                : loaded.filteredListings;

            return Column(
              children: [
                const SizedBox(height: AppSpacing.p8),
                CategoryFilterBar(
                  selected: loaded.selectedCategory,
                  onSelected: (cat) => context
                      .read<ListingsBloc>()
                      .add(ListingsCategoryChanged(cat)),
                ),
                const SizedBox(height: AppSpacing.p8),
                Expanded(
                  child: items.isEmpty
                      ? _buildEmptyState(context, loaded)
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final listing = items[index];
                            return ListingCard(
                              listing: listing,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ListingDetailScreen(
                                    listing: listing,
                                    canEdit: _canEdit(context, listing.createdBy),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
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
