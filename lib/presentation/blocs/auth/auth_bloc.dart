import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/domain/models/user_profile.dart';
import 'package:kigali_connect/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<_AuthUserChanged>(_onAuthUserChanged);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthVerificationEmailRequested>(_onVerificationEmailRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final AuthRepository _authRepository;
  StreamSubscription<User?>? _authStateSubscription;

  void _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) {
    _authStateSubscription?.cancel();
    _authStateSubscription = _authRepository.authStateChanges.listen(
      (user) => add(_AuthUserChanged(user)),
    );
  }

  Future<void> _onAuthUserChanged(
    _AuthUserChanged event,
    Emitter<AuthState> emit,
  ) async {
    final user = event.user;
    if (user == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    if (!user.emailVerified) {
      emit(const AuthEmailNotVerified());
      return;
    }
    emit(const AuthLoading());
    try {
      var profile = await _authRepository.getCurrentUserProfile();
      // Fallback: profile may not exist yet if the Firestore write during
      // registration failed (race condition). Create it now from Auth data.
      profile ??= await _authRepository.createProfileFromCurrentUser();
      if (profile != null) {
        emit(AuthAuthenticated(profile));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final profile = await _authRepository.signIn(
        email: event.email,
        password: event.password,
      );
      emit(AuthAuthenticated(profile));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _authRepository.register(
        email: event.email,
        password: event.password,
        displayName: event.displayName,
      );
      await _authRepository.sendEmailVerification();
      emit(const AuthEmailNotVerified());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final profile = await _authRepository.signInWithGoogle();
      emit(AuthAuthenticated(profile));
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      final msg = e.toString();
      // User cancelled the Google picker — don't show an error
      if (msg.contains('cancelled')) {
        emit(const AuthUnauthenticated());
      } else {
        emit(AuthFailure(msg));
      }
    }
  }

  Future<void> _onVerificationEmailRequested(
    AuthVerificationEmailRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await _authRepository.sendEmailVerification();
      emit(const AuthVerificationEmailSent());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _authRepository.signOut();
    emit(const AuthUnauthenticated());
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }
}
