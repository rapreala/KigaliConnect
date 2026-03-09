import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/models/listing.dart';
import 'package:kigali_connect/domain/repositories/listings_repository.dart';

class FirebaseListingsRepository implements ListingsRepository {
  FirebaseListingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _listings =>
      _firestore.collection('listings');

  @override
  Stream<List<Listing>> watchListings({PlaceCategory? category}) {
    Query<Map<String, dynamic>> query =
        _listings.orderBy('createdAt', descending: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category.toJson());
    }

    return query.snapshots().map(
          (snap) => snap.docs
              .map((d) {
                try {
                  return Listing.fromJson(d.data());
                } catch (_) {
                  return null;
                }
              })
              .whereType<Listing>()
              .toList(),
        );
  }

  @override
  Future<Listing?> getListingById(String id) async {
    final doc = await _listings.doc(id).get();
    if (!doc.exists) return null;
    return Listing.fromJson(doc.data()!);
  }

  @override
  Future<Listing> createListing(Listing listing) async {
    final docRef = _listings.doc();
    final withId = listing.copyWith(id: docRef.id);
    await docRef.set(withId.toJson());
    return withId;
  }

  @override
  Future<void> updateListing(Listing listing) async {
    await _listings.doc(listing.id).set(listing.toJson());
  }

  @override
  Future<void> deleteListing(String id) async {
    await _listings.doc(id).delete();
  }
}
