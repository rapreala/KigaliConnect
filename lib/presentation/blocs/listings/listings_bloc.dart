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
    on<ListingsCategoryChanged>(_onCategoryChanged);
    on<ListingsSearchChanged>(_onSearchChanged);
    on<ListingCreated>(_onListingCreated);
    on<ListingUpdated>(_onListingUpdated);
    on<ListingDeleted>(_onListingDeleted);
  }

  final ListingsRepository _repo;
  StreamSubscription<List<Listing>>? _listingsSubscription;
  PlaceCategory? _activeCategory;
  String _searchQuery = '';

  void _onSubscriptionRequested(
    ListingsSubscriptionRequested event,
    Emitter<ListingsState> emit,
  ) {
    _activeCategory = event.category;
    emit(const ListingsLoading());
    _listingsSubscription?.cancel();
    _listingsSubscription = _repo
        .watchListings(category: event.category)
        .listen(
          (listings) => add(_ListingsUpdated(listings)),
          onError: (Object e) => emit(ListingsError(e.toString())),
        );
  }

  void _onListingsUpdated(
    _ListingsUpdated event,
    Emitter<ListingsState> emit,
  ) {
    emit(ListingsLoaded(
      listings: event.listings,
      filteredListings: _applyFilter(event.listings),
      selectedCategory: _activeCategory,
      searchQuery: _searchQuery,
    ));
  }

  void _onCategoryChanged(
    ListingsCategoryChanged event,
    Emitter<ListingsState> emit,
  ) {
    _activeCategory = event.category;
    _listingsSubscription?.cancel();
    _listingsSubscription = _repo
        .watchListings(category: event.category)
        .listen(
          (listings) => add(_ListingsUpdated(listings)),
          onError: (Object e) => emit(ListingsError(e.toString())),
        );
  }

  void _onSearchChanged(
    ListingsSearchChanged event,
    Emitter<ListingsState> emit,
  ) {
    _searchQuery = event.query.toLowerCase();
    final current = state;
    if (current is ListingsLoaded) {
      emit(current.copyWith(
        filteredListings: _applyFilter(current.listings),
        searchQuery: event.query,
      ));
    }
  }

  Future<void> _onListingCreated(
    ListingCreated event,
    Emitter<ListingsState> emit,
  ) async {
    try {
      await _repo.createListing(event.listing);
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
      emit(const ListingsActionSuccess('Listing updated successfully.'));
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
      emit(const ListingsActionSuccess('Listing deleted.'));
    } catch (e) {
      emit(ListingsError(e.toString()));
    }
  }

  List<Listing> _applyFilter(List<Listing> all) {
    if (_searchQuery.isEmpty) return all;
    return all.where((l) {
      return l.name.toLowerCase().contains(_searchQuery) ||
          l.address.toLowerCase().contains(_searchQuery) ||
          l.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Future<void> close() {
    _listingsSubscription?.cancel();
    return super.close();
  }
}
