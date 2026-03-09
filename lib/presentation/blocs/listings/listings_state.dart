part of 'listings_bloc.dart';

abstract class ListingsState extends Equatable {
  const ListingsState();

  @override
  List<Object?> get props => [];
}

class ListingsInitial extends ListingsState {
  const ListingsInitial();
}

class ListingsLoading extends ListingsState {
  const ListingsLoading();
}

class ListingsLoaded extends ListingsState {
  const ListingsLoaded({
    required this.allListings,
    required this.listings,
    this.filteredListings = const [],
    this.selectedCategory,
    this.searchQuery = '',
  });

  /// Every listing from Firestore — unaffected by category or search filter.
  /// Used by MapViewScreen to always show all markers.
  final List<Listing> allListings;

  /// Category-filtered listings (or all if no category selected).
  final List<Listing> listings;
  final List<Listing> filteredListings;
  final PlaceCategory? selectedCategory;
  final String searchQuery;

  ListingsLoaded copyWith({
    List<Listing>? allListings,
    List<Listing>? listings,
    List<Listing>? filteredListings,
    PlaceCategory? selectedCategory,
    bool clearCategory = false,
    String? searchQuery,
  }) {
    return ListingsLoaded(
      allListings: allListings ?? this.allListings,
      listings: listings ?? this.listings,
      filteredListings: filteredListings ?? this.filteredListings,
      selectedCategory:
          clearCategory ? null : selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        allListings,
        listings,
        filteredListings,
        selectedCategory,
        searchQuery,
      ];
}

class ListingsActionSuccess extends ListingsState {
  const ListingsActionSuccess(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ListingsError extends ListingsState {
  const ListingsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
