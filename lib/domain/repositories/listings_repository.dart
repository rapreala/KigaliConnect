import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/domain/models/enums.dart';

abstract class ListingsRepository {
  /// Real-time stream of all listings (optionally filtered by category)
  Stream<List<Listing>> watchListings({PlaceCategory? category});

  /// Fetch a single listing by ID
  Future<Listing?> getListingById(String id);

  /// Create a new listing; returns the created Listing with its Firestore ID
  Future<Listing> createListing(Listing listing);

  /// Update an existing listing
  Future<void> updateListing(Listing listing);

  /// Delete a listing by ID
  Future<void> deleteListing(String id);
}
