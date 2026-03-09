import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_connect/domain/validators/listing_validator.dart';

void main() {
  // ── validateName ──────────────────────────────────────────────────────────
  group('ListingValidator.validateName', () {
    test('returns null for valid name', () {
      expect(ListingValidator.validateName('King Faisal Hospital'), isNull);
    });

    test('returns error for null input', () {
      expect(ListingValidator.validateName(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ListingValidator.validateName(''), isNotNull);
    });

    test('returns error for whitespace-only string', () {
      expect(ListingValidator.validateName('   '), isNotNull);
    });

    test('returns null for name at exactly 100 characters', () {
      final name = 'A' * 100;
      expect(ListingValidator.validateName(name), isNull);
    });

    test('returns error for name exceeding 100 characters', () {
      final name = 'A' * 101;
      expect(ListingValidator.validateName(name), isNotNull);
    });
  });

  // ── validateAddress ───────────────────────────────────────────────────────
  group('ListingValidator.validateAddress', () {
    test('returns null for valid address', () {
      expect(ListingValidator.validateAddress('KG 544 St, Kigali'), isNull);
    });

    test('returns error for null input', () {
      expect(ListingValidator.validateAddress(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ListingValidator.validateAddress(''), isNotNull);
    });

    test('returns error for whitespace-only string', () {
      expect(ListingValidator.validateAddress('   '), isNotNull);
    });
  });

  // ── validateContactNumber ─────────────────────────────────────────────────
  group('ListingValidator.validateContactNumber', () {
    test('returns null for valid international number', () {
      expect(ListingValidator.validateContactNumber('+250788000000'), isNull);
    });

    test('returns null for plain digits', () {
      expect(ListingValidator.validateContactNumber('0788000000'), isNull);
    });

    test('returns null for number with spaces and dashes', () {
      expect(ListingValidator.validateContactNumber('+250 788-000-000'), isNull);
    });

    test('returns error for null input', () {
      expect(ListingValidator.validateContactNumber(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ListingValidator.validateContactNumber(''), isNotNull);
    });

    test('returns error for too few digits (< 7)', () {
      expect(ListingValidator.validateContactNumber('12345'), isNotNull);
    });

    test('returns error for too many digits (> 15)', () {
      expect(ListingValidator.validateContactNumber('1234567890123456'), isNotNull);
    });

    test('returns null for minimum valid length (7 digits)', () {
      expect(ListingValidator.validateContactNumber('1234567'), isNull);
    });

    test('returns null for maximum valid length (15 digits)', () {
      expect(ListingValidator.validateContactNumber('123456789012345'), isNull);
    });

    test('returns error for alphabetic input', () {
      expect(ListingValidator.validateContactNumber('abcdefghij'), isNotNull);
    });
  });

  // ── validateDescription ───────────────────────────────────────────────────
  group('ListingValidator.validateDescription', () {
    test('returns null for valid description', () {
      expect(ListingValidator.validateDescription('A great hospital.'), isNull);
    });

    test('returns error for null input', () {
      expect(ListingValidator.validateDescription(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ListingValidator.validateDescription(''), isNotNull);
    });

    test('returns null for description at exactly 500 characters', () {
      final desc = 'D' * 500;
      expect(ListingValidator.validateDescription(desc), isNull);
    });

    test('returns error for description exceeding 500 characters', () {
      final desc = 'D' * 501;
      expect(ListingValidator.validateDescription(desc), isNotNull);
    });
  });

  // ── validateLatitude ──────────────────────────────────────────────────────
  group('ListingValidator.validateLatitude', () {
    test('returns null for valid Kigali latitude', () {
      expect(ListingValidator.validateLatitude('-1.9441'), isNull);
    });

    test('returns null for latitude 0', () {
      expect(ListingValidator.validateLatitude('0'), isNull);
    });

    test('returns null for boundary -90', () {
      expect(ListingValidator.validateLatitude('-90'), isNull);
    });

    test('returns null for boundary 90', () {
      expect(ListingValidator.validateLatitude('90'), isNull);
    });

    test('returns error for latitude below -90', () {
      expect(ListingValidator.validateLatitude('-90.1'), isNotNull);
    });

    test('returns error for latitude above 90', () {
      expect(ListingValidator.validateLatitude('90.1'), isNotNull);
    });

    test('returns error for non-numeric input', () {
      expect(ListingValidator.validateLatitude('abc'), isNotNull);
    });

    test('returns error for null input', () {
      expect(ListingValidator.validateLatitude(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ListingValidator.validateLatitude(''), isNotNull);
    });
  });

  // ── validateLongitude ─────────────────────────────────────────────────────
  group('ListingValidator.validateLongitude', () {
    test('returns null for valid Kigali longitude', () {
      expect(ListingValidator.validateLongitude('30.0619'), isNull);
    });

    test('returns null for longitude 0', () {
      expect(ListingValidator.validateLongitude('0'), isNull);
    });

    test('returns null for boundary -180', () {
      expect(ListingValidator.validateLongitude('-180'), isNull);
    });

    test('returns null for boundary 180', () {
      expect(ListingValidator.validateLongitude('180'), isNull);
    });

    test('returns error for longitude below -180', () {
      expect(ListingValidator.validateLongitude('-180.1'), isNotNull);
    });

    test('returns error for longitude above 180', () {
      expect(ListingValidator.validateLongitude('180.1'), isNotNull);
    });

    test('returns error for non-numeric input', () {
      expect(ListingValidator.validateLongitude('xyz'), isNotNull);
    });

    test('returns error for null input', () {
      expect(ListingValidator.validateLongitude(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(ListingValidator.validateLongitude(''), isNotNull);
    });
  });
}
