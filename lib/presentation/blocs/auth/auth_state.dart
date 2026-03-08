part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state before auth check
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Checking Firebase auth state
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated + email verified
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.profile);
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

/// Authenticated but email not yet verified
class AuthEmailNotVerified extends AuthState {
  const AuthEmailNotVerified();
}

/// Not signed in
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed
class AuthFailure extends AuthState {
  const AuthFailure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Verification email sent successfully
class AuthVerificationEmailSent extends AuthState {
  const AuthVerificationEmailSent();
}
