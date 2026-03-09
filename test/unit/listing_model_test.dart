import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_connect/domain/models/enums.dart';
import 'package:kigali_connect/domain/models/listing.dart';

void main() {
  final _createdAt = DateTime(2024, 6, 1, 10, 0);
  final _updatedAt = DateTime(2024, 6, 2, 12, 0);

  Listing _baseListing() => Listing(
        id: 'listing-1',
        name: 'King Faisal Hospital',
        category: PlaceCategory.hospital,
        address: 'KG 544 St, Kigali',
        contactNumber: '+250788000000',
        description: 'Main referral hospital in Kigali.',
        latitude: -1.9441,
        longitude: 30.0619,
        createdBy: 'user-abc',
        createdAt: _createdAt,
        updatedAt: _updatedAt,
      );

  group('Listing.toJson / fromJson', () {
    test('round-trips all fields correctly', () {
      final original = _baseListing();
      final json = original.toJson();
      final restored = Listing.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.address, original.address);
      expect(restored.contactNumber, original.contactNumber);
      expect(restored.description, original.description);
      expect(restored.latitude, original.latitude);
      expect(restored.longitude, original.longitude);
      expect(restored.createdBy, original.createdBy);
      expect(restored.createdAt, original.createdAt);
      expect(restored.updatedAt, original.updatedAt);
    });

    test('toJson serialises category as enum name string', () {
      final json = _baseListing().toJson();
      expect(json['category'], 'hospital');
    });

    test('toJson serialises dates as Firestore Timestamps', () {
      final json = _baseListing().toJson();
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['updatedAt'], isA<Timestamp>());
    });

    test('fromJson handles int latitude/longitude (Firestore stores as num)', () {
      final json = _baseListing().toJson();
      // Replace doubles with ints to simulate Firestore int storage
      json['latitude'] = -2;
      json['longitude'] = 30;
      final listing = Listing.fromJson(json);
      expect(listing.latitude, -2.0);
      expect(listing.longitude, 30.0);
    });

    test('round-trips every PlaceCategory variant', () {
      for (final cat in PlaceCategory.values) {
        final listing = _baseListing().copyWith(category: cat);
        final restored = Listing.fromJson(listing.toJson());
        expect(restored.category, cat);
      }
    });
  });

  group('Listing.copyWith', () {
    test('returns equal object when no overrides given', () {
      final original = _baseListing();
      final copy = original.copyWith();
      expect(copy, original);
    });

    test('overrides only the specified fields', () {
      final original = _baseListing();
      final copy = original.copyWith(
        name: 'Updated Name',
        category: PlaceCategory.park,
      );

      expect(copy.name, 'Updated Name');
      expect(copy.category, PlaceCategory.park);
      // Unchanged fields
      expect(copy.id, original.id);
      expect(copy.address, original.address);
      expect(copy.latitude, original.latitude);
      expect(copy.createdBy, original.createdBy);
    });

    test('original is not mutated after copyWith', () {
      final original = _baseListing();
      original.copyWith(name: 'Changed');
      expect(original.name, 'King Faisal Hospital');
    });
  });

  group('Listing equality', () {
    test('two listings with same id/fields are equal', () {
      expect(_baseListing(), _baseListing());
    });

    test('listings with different ids are not equal', () {
      final a = _baseListing();
      final b = _baseListing().copyWith(id: 'listing-2');
      expect(a, isNot(b));
    });

    test('listings with different names are not equal', () {
      final a = _baseListing();
      final b = _baseListing().copyWith(name: 'Other Place');
      expect(a, isNot(b));
    });

    test('hashCodes match for equal listings', () {
      expect(_baseListing().hashCode, _baseListing().hashCode);
    });
  });

  group('Listing.toString', () {
    test('contains name and id', () {
      final s = _baseListing().toString();
      expect(s, contains('King Faisal Hospital'));
      expect(s, contains('listing-1'));
    });
  });
}
