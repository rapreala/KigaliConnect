part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

/// Fired on app start — listens to Firebase auth state changes
class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// Internal — emitted when Firebase auth state changes
class _AuthUserChanged extends AuthEvent {
  const _AuthUserChanged(this.user);
  final User? user;

  @override
  List<Object?> get props => [user?.uid];
}

/// User tapped "Sign In"
class AuthSignInRequested extends AuthEvent {
  const AuthSignInRequested({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

/// User tapped "Register"
class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.displayName,
  });
  final String email;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}

/// User tapped "Sign in with Google"
class AuthGoogleSignInRequested extends AuthEvent {
  const AuthGoogleSignInRequested();
}

/// User tapped "Resend verification email"
class AuthVerificationEmailRequested extends AuthEvent {
  const AuthVerificationEmailRequested();
}

/// User tapped "Sign Out"
class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}
