import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/domain/repositories/listings_repository.dart';

part 'listings_event.dart';
part 'listings_state.dart';

class ListingsBloc extends Bloc<ListingsEvent, ListingsState> {
  ListingsBloc({required ListingsRepository listingsRepository})
      : _repo = listingsRepository,
        super(const ListingsInitial()) {
    on<ListingsSubscriptionRequested>(_onSubscriptionRequested);
    on<_ListingsUpdated>(_onListingsUpdated);
    on<_ListingsStreamErrored>(_onStreamErrored);
    on<ListingsCategoryChanged>(_onCategoryChanged);
    on<ListingsSearchChanged>(_onSearchChanged);
    on<ListingCreated>(_onListingCreated);
    on<ListingUpdated>(_onListingUpdated);
    on<ListingDeleted>(_onListingDeleted);
  }

  final ListingsRepository _repo;
  StreamSubscription<List<Listing>>? _listingsSubscription;

  // Master list — all listings from Firestore, unfiltered.
  List<Listing> _allListings = [];
  PlaceCategory? _activeCategory;
  String _searchQuery = '';

  void _onSubscriptionRequested(
    ListingsSubscriptionRequested event,
    Emitter<ListingsState> emit,
  ) {
    emit(const ListingsLoading());
    _subscribe();
  }

  void _subscribe() {
    _listingsSubscription?.cancel();
    // Always stream ALL listings — category filtering is done client-side so
    // switching categories is instant without a new Firestore round-trip.
    _listingsSubscription = _repo.watchListings().listen(
          (listings) => add(_ListingsUpdated(listings)),
          onError: (Object e) => add(_ListingsStreamErrored(e.toString())),
        );
  }

  void _onListingsUpdated(
    _ListingsUpdated event,
    Emitter<ListingsState> emit,
  ) {
    _allListings = event.listings;
    emit(_buildLoaded());
  }

  void _onStreamErrored(
    _ListingsStreamErrored event,
    Emitter<ListingsState> emit,
  ) {
    if (state is! ListingsLoaded) {
      emit(ListingsError(event.message));
    }
    _subscribe();
  }

  void _onCategoryChanged(
    ListingsCategoryChanged event,
    Emitter<ListingsState> emit,
  ) {
    _activeCategory = event.category;
    // Client-side filter — instant, no Firestore round-trip needed.
    emit(_buildLoaded());
  }

  void _onSearchChanged(
    ListingsSearchChanged event,
    Emitter<ListingsState> emit,
  ) {
    _searchQuery = event.query.toLowerCase();
    emit(_buildLoaded());
  }

  Future<void> _onListingCreated(
    ListingCreated event,
    Emitter<ListingsState> emit,
  ) async {
    try {
      await _repo.createListing(event.listing);
      // No optimistic prepend — Firestore's local cache fires the stream
      // immediately, so the new listing appears via _onListingsUpdated without
      // any visible delay. Prepending here caused a duplicate because
      // _onListingsUpdated runs concurrently and already updated _allListings.
      emit(const ListingsActionSuccess('Listing added successfully.'));
    } catch (e) {
      emit(ListingsError(e.toString()));
    }
  }

  Future<void> _onListingUpdated(
    ListingUpdated event,
    Emitter<ListingsState> emit,
  ) async {
    try {
      await _repo.updateListing(event.listing);
      _allListings = _allListings
          .map((l) => l.id == event.listing.id ? event.listing : l)
          .toList();
      emit(const ListingsActionSuccess('Listing updated successfully.'));
      emit(_buildLoaded());
    } catch (e) {
      emit(ListingsError(e.toString()));
    }
  }

  Future<void> _onListingDeleted(
    ListingDeleted event,
    Emitter<ListingsState> emit,
  ) async {
    try {
      await _repo.deleteListing(event.id);
      _allListings = _allListings.where((l) => l.id != event.id).toList();
      emit(const ListingsActionSuccess('Listing deleted.'));
      emit(_buildLoaded());
    } catch (e) {
      emit(ListingsError(e.toString()));
    }
  }

  /// Builds a [ListingsLoaded] from [_allListings] applying both the active
  /// category filter and the current search query.
  ListingsLoaded _buildLoaded() {
    final byCategory = _activeCategory == null
        ? _allListings
        : _allListings
            .where((l) => l.category == _activeCategory)
            .toList();

    final bySearch = _searchQuery.isEmpty
        ? byCategory
        : byCategory.where((l) {
            return l.name.toLowerCase().contains(_searchQuery) ||
                l.address.toLowerCase().contains(_searchQuery) ||
                l.description.toLowerCase().contains(_searchQuery);
          }).toList();

    return ListingsLoaded(
      allListings: _allListings,
      listings: byCategory,
      filteredListings: bySearch,
      selectedCategory: _activeCategory,
      searchQuery: _searchQuery,
    );
  }

  @override
  Future<void> close() {
    _listingsSubscription?.cancel();
    return super.close();
  }
}
