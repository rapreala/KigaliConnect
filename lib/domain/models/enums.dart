import 'package:flutter/material.dart';
import 'package:kigali_connect/config/theme.dart';

enum PlaceCategory {
  hospital,
  policeStation,
  library,
  restaurantCafe,
  park,
  touristAttraction,
  utilityOffice,
}

extension PlaceCategoryExtension on PlaceCategory {
  String get displayName {
    switch (this) {
      case PlaceCategory.hospital:          return 'Hospital';
      case PlaceCategory.policeStation:     return 'Police Station';
      case PlaceCategory.library:           return 'Library';
      case PlaceCategory.restaurantCafe:    return 'Restaurant / Café';
      case PlaceCategory.park:              return 'Park';
      case PlaceCategory.touristAttraction: return 'Tourist Attraction';
      case PlaceCategory.utilityOffice:     return 'Utility Office';
    }
  }

  IconData get iconData {
    switch (this) {
      case PlaceCategory.hospital:          return Icons.local_hospital;
      case PlaceCategory.policeStation:     return Icons.local_police;
      case PlaceCategory.library:           return Icons.menu_book;
      case PlaceCategory.restaurantCafe:    return Icons.restaurant;
      case PlaceCategory.park:              return Icons.park;
      case PlaceCategory.touristAttraction: return Icons.photo_camera;
      case PlaceCategory.utilityOffice:     return Icons.business;
    }
  }

  Color get iconColor {
    switch (this) {
      case PlaceCategory.hospital:          return AppColors.iconHospital;
      case PlaceCategory.policeStation:     return AppColors.iconPolice;
      case PlaceCategory.library:           return AppColors.iconLibrary;
      case PlaceCategory.restaurantCafe:    return AppColors.iconRestaurant;
      case PlaceCategory.park:              return AppColors.iconPark;
      case PlaceCategory.touristAttraction: return AppColors.iconTourist;
      case PlaceCategory.utilityOffice:     return AppColors.iconUtility;
    }
  }

  String toJson() => name;

  static PlaceCategory fromJson(String value) {
    return PlaceCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => PlaceCategory.hospital,
    );
  }
}
