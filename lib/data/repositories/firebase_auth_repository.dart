import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kigali_connect/domain/models/user_profile.dart';
import 'package:kigali_connect/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  Future<UserProfile> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      if (_auth.currentUser == null) rethrow;
    }
    final uid = _auth.currentUser!.uid;
    final profile = await _fetchProfile(uid);
    if (profile == null) {
      throw Exception('User profile not found. Please contact support.');
    }
    return profile;
  }

  @override
  Future<UserProfile> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      // firebase_auth 4.x on Android throws a Pigeon type-cast error during
      // response deserialization even when the account IS created successfully.
      // If currentUser is now set, the signup succeeded — ignore the error.
      if (_auth.currentUser == null) rethrow;
    }
    final uid = _auth.currentUser!.uid;

    final profile = UserProfile(
      uid: uid,
      email: email.trim(),
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
    );

    await _users.doc(uid).set(profile.toJson());
    return profile;
  }

  @override
  Future<UserProfile> signInWithGoogle() async {
    // Trigger the Google Sign-In flow
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled.');
    }

    // Obtain auth tokens
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;

    // Create Firestore profile if this is the first sign-in
    final existing = await _fetchProfile(user.uid);
    if (existing != null) return existing;

    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? googleUser.displayName ?? 'User',
      createdAt: DateTime.now(),
    );
    await _users.doc(user.uid).set(profile.toJson());
    return profile;
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return _fetchProfile(user.uid);
  }

  @override
  Future<UserProfile?> createProfileFromCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final existing = await _fetchProfile(user.uid);
    if (existing != null) return existing;
    final profile = UserProfile(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.email ?? 'User',
      createdAt: DateTime.now(),
    );
    await _users.doc(user.uid).set(profile.toJson());
    return profile;
  }

  Future<UserProfile?> _fetchProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromJson(doc.data()!);
  }
}
