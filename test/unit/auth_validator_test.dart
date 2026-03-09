import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_connect/domain/validators/auth_validator.dart';

void main() {
  // ── validateEmail ─────────────────────────────────────────────────────────
  group('AuthValidator.validateEmail', () {
    test('returns null for valid email', () {
      expect(AuthValidator.validateEmail('user@example.com'), isNull);
    });

    test('returns null for email with hyphenated domain', () {
      expect(AuthValidator.validateEmail('user@my-company.org'), isNull);
    });

    test('returns null for email with plus and dots', () {
      expect(AuthValidator.validateEmail('user.name+tag@example.org'), isNull);
    });

    test('returns error for null input', () {
      expect(AuthValidator.validateEmail(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(AuthValidator.validateEmail(''), isNotNull);
    });

    test('returns error for missing @', () {
      expect(AuthValidator.validateEmail('userexample.com'), isNotNull);
    });

    test('returns error for missing domain', () {
      expect(AuthValidator.validateEmail('user@'), isNotNull);
    });

    test('returns error for missing TLD', () {
      expect(AuthValidator.validateEmail('user@example'), isNotNull);
    });

    test('returns error for TLD of only 1 character', () {
      expect(AuthValidator.validateEmail('user@example.c'), isNotNull);
    });

    test('returns error for whitespace-only string', () {
      expect(AuthValidator.validateEmail('   '), isNotNull);
    });
  });

  // ── validatePassword ──────────────────────────────────────────────────────
  group('AuthValidator.validatePassword', () {
    test('returns null for valid password', () {
      expect(AuthValidator.validatePassword('secret123'), isNull);
    });

    test('returns null for password exactly 6 characters', () {
      expect(AuthValidator.validatePassword('abcdef'), isNull);
    });

    test('returns error for null input', () {
      expect(AuthValidator.validatePassword(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(AuthValidator.validatePassword(''), isNotNull);
    });

    test('returns error for password shorter than 6 characters', () {
      expect(AuthValidator.validatePassword('abc'), isNotNull);
    });

    test('returns error for 5-character password', () {
      expect(AuthValidator.validatePassword('12345'), isNotNull);
    });

    test('returns null for long password', () {
      expect(AuthValidator.validatePassword('A' * 64), isNull);
    });
  });

  // ── validateConfirmPassword ───────────────────────────────────────────────
  group('AuthValidator.validateConfirmPassword', () {
    test('returns null when passwords match', () {
      expect(
        AuthValidator.validateConfirmPassword('password123', 'password123'),
        isNull,
      );
    });

    test('returns error for null input', () {
      expect(
        AuthValidator.validateConfirmPassword(null, 'password123'),
        isNotNull,
      );
    });

    test('returns error for empty string', () {
      expect(
        AuthValidator.validateConfirmPassword('', 'password123'),
        isNotNull,
      );
    });

    test('returns error when passwords do not match', () {
      expect(
        AuthValidator.validateConfirmPassword('different', 'password123'),
        isNotNull,
      );
    });

    test('is case-sensitive', () {
      expect(
        AuthValidator.validateConfirmPassword('Password123', 'password123'),
        isNotNull,
      );
    });
  });

  // ── validateDisplayName ───────────────────────────────────────────────────
  group('AuthValidator.validateDisplayName', () {
    test('returns null for valid name', () {
      expect(AuthValidator.validateDisplayName('Alice'), isNull);
    });

    test('returns null for name at exactly 50 characters', () {
      expect(AuthValidator.validateDisplayName('A' * 50), isNull);
    });

    test('returns error for null input', () {
      expect(AuthValidator.validateDisplayName(null), isNotNull);
    });

    test('returns error for empty string', () {
      expect(AuthValidator.validateDisplayName(''), isNotNull);
    });

    test('returns error for whitespace-only string', () {
      expect(AuthValidator.validateDisplayName('   '), isNotNull);
    });

    test('returns error for name exceeding 50 characters', () {
      expect(AuthValidator.validateDisplayName('A' * 51), isNotNull);
    });
  });
}
