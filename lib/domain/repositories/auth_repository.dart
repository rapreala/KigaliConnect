import 'package:firebase_auth/firebase_auth.dart';
import 'package:kigali_connect/domain/models/user_profile.dart';

abstract class AuthRepository {
  /// Stream of auth state changes (null = signed out)
  Stream<User?> get authStateChanges;

  /// Sign in with email and password
  Future<UserProfile> signIn({
    required String email,
    required String password,
  });

  /// Register a new user and create their Firestore profile
  Future<UserProfile> register({
    required String email,
    required String password,
    required String displayName,
  });

  /// Send email verification to the current user
  Future<void> sendEmailVerification();

  /// Sign in with Google OAuth — creates Firestore profile on first sign-in
  Future<UserProfile> signInWithGoogle();

  /// Sign out the current user
  Future<void> signOut();

  /// Fetch the UserProfile for the currently signed-in user
  Future<UserProfile?> getCurrentUserProfile();

  /// Create a Firestore profile from the current Firebase Auth user.
  /// Used as a fallback when the profile write during registration failed.
  /// Returns null if no user is signed in.
  Future<UserProfile?> createProfileFromCurrentUser();
}
