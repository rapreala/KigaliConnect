class ListingValidator {
  ListingValidator._();

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Place name is required';
    }
    if (value.trim().length > 100) {
      return 'Name must be 100 characters or fewer';
    }
    return null;
  }

  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    return null;
  }

  static String? validateContactNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    final digits = value.trim().replaceAll(RegExp(r'[\s\-\+]'), '');
    if (!RegExp(r'^\d{7,15}$').hasMatch(digits)) {
      return 'Enter a valid phone number (7–15 digits)';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length > 500) {
      return 'Description must be 500 characters or fewer';
    }
    return null;
  }

  static String? validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Latitude is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number (e.g. -1.9441)';
    }
    if (parsed < -90 || parsed > 90) {
      return 'Latitude must be between -90 and 90';
    }
    return null;
  }

  static String? validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Longitude is required';
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid number (e.g. 30.0619)';
    }
    if (parsed < -180 || parsed > 180) {
      return 'Longitude must be between -180 and 180';
    }
    return null;
  }
}
