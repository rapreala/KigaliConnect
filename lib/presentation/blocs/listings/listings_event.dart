part of 'listings_bloc.dart';

abstract class ListingsEvent extends Equatable {
  const ListingsEvent();

  @override
  List<Object?> get props => [];
}

/// Start listening to the listings stream
class ListingsSubscriptionRequested extends ListingsEvent {
  const ListingsSubscriptionRequested();
}

/// Internal — new snapshot from the Firestore stream
class _ListingsUpdated extends ListingsEvent {
  const _ListingsUpdated(this.listings);
  final List<Listing> listings;

  @override
  List<Object?> get props => [listings];
}

/// Internal — stream emitted an error; triggers auto-resubscribe
class _ListingsStreamErrored extends ListingsEvent {
  const _ListingsStreamErrored(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// User changed the category filter chip
class ListingsCategoryChanged extends ListingsEvent {
  const ListingsCategoryChanged(this.category);
  final PlaceCategory? category;

  @override
  List<Object?> get props => [category];
}

/// User submitted the search query
class ListingsSearchChanged extends ListingsEvent {
  const ListingsSearchChanged(this.query);
  final String query;

  @override
  List<Object?> get props => [query];
}

/// User tapped "Add listing" and submitted the form
class ListingCreated extends ListingsEvent {
  const ListingCreated(this.listing);
  final Listing listing;

  @override
  List<Object?> get props => [listing];
}

/// User submitted the edit form
class ListingUpdated extends ListingsEvent {
  const ListingUpdated(this.listing);
  final Listing listing;

  @override
  List<Object?> get props => [listing];
}

/// User confirmed delete
class ListingDeleted extends ListingsEvent {
  const ListingDeleted(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}
