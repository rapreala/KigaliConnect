import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:kigali_connect/domain/models/enums.dart';

class Listing {
  final String id;
  final String name;
  final PlaceCategory category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Listing({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id':            id,
      'name':          name,
      'category':      category.toJson(),
      'address':       address,
      'contactNumber': contactNumber,
      'description':   description,
      'latitude':      latitude,
      'longitude':     longitude,
      'createdBy':     createdBy,
      'createdAt':     Timestamp.fromDate(createdAt),
      'updatedAt':     Timestamp.fromDate(updatedAt),
    };
  }

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id:            json['id'] as String,
      name:          json['name'] as String,
      category:      PlaceCategoryExtension.fromJson(json['category'] as String),
      address:       json['address'] as String,
      contactNumber: json['contactNumber'] as String,
      description:   json['description'] as String,
      latitude:      (json['latitude'] as num).toDouble(),
      longitude:     (json['longitude'] as num).toDouble(),
      createdBy:     json['createdBy'] as String,
      createdAt:     (json['createdAt'] as Timestamp).toDate(),
      updatedAt:     (json['updatedAt'] as Timestamp).toDate(),
    );
  }

  Listing copyWith({
    String? id,
    String? name,
    PlaceCategory? category,
    String? address,
    String? contactNumber,
    String? description,
    double? latitude,
    double? longitude,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Listing(
      id:            id            ?? this.id,
      name:          name          ?? this.name,
      category:      category      ?? this.category,
      address:       address       ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      description:   description   ?? this.description,
      latitude:      latitude      ?? this.latitude,
      longitude:     longitude     ?? this.longitude,
      createdBy:     createdBy     ?? this.createdBy,
      createdAt:     createdAt     ?? this.createdAt,
      updatedAt:     updatedAt     ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Listing &&
        other.id            == id &&
        other.name          == name &&
        other.category      == category &&
        other.address       == address &&
        other.contactNumber == contactNumber &&
        other.description   == description &&
        other.latitude      == latitude &&
        other.longitude     == longitude &&
        other.createdBy     == createdBy;
  }

  @override
  int get hashCode => Object.hash(
    id, name, category, address, contactNumber,
    description, latitude, longitude, createdBy,
  );

  @override
  String toString() =>
      'Listing(id: $id, name: $name, category: ${category.displayName}, address: $address)';
}
