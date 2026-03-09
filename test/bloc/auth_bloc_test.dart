import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kigali_connect/domain/models/user_profile.dart';
import 'package:kigali_connect/domain/repositories/auth_repository.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_bloc_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  late MockAuthRepository mockRepo;

  // ── helpers ──────────────────────────────────────────────────────────────

  UserProfile makeProfile({String uid = 'uid-1'}) => UserProfile(
        uid: uid,
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2024, 1, 1),
      );

  setUp(() {
    mockRepo = MockAuthRepository();
    // Default: authStateChanges never emits (prevents side-effects in tests
    // that don't exercise the subscription path).
    when(mockRepo.authStateChanges)
        .thenAnswer((_) => const Stream.empty());
  });

  // ── sign out ──────────────────────────────────────────────────────────────

  group('AuthSignOutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'calls signOut and emits AuthUnauthenticated',
      build: () {
        when(mockRepo.signOut()).thenAnswer((_) => Future<void>.value());
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthSignOutRequested()),
      expect: () => [const AuthUnauthenticated()],
      verify: (_) => verify(mockRepo.signOut()).called(1),
    );
  });

  // ── register ──────────────────────────────────────────────────────────────

  group('AuthRegisterRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthEmailNotVerified] on success',
      build: () {
        when(mockRepo.register(
          email: 'user@example.com',
          password: 'password123',
          displayName: 'Alice',
        )).thenAnswer((_) async => makeProfile());
        when(mockRepo.sendEmailVerification()).thenAnswer((_) => Future<void>.value());
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        email: 'user@example.com',
        password: 'password123',
        displayName: 'Alice',
      )),
      expect: () => [
        const AuthLoading(),
        const AuthEmailNotVerified(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when register throws',
      build: () {
        when(mockRepo.register(
          email: anyNamed('email'),
          password: anyNamed('password'),
          displayName: anyNamed('displayName'),
        )).thenThrow(Exception('Registration failed'));
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthRegisterRequested(
        email: 'bad@example.com',
        password: 'pass123',
        displayName: 'Bob',
      )),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>(),
      ],
    );
  });

  // ── google sign-in ────────────────────────────────────────────────────────

  group('AuthGoogleSignInRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on success',
      build: () {
        when(mockRepo.signInWithGoogle())
            .thenAnswer((_) async => makeProfile());
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        AuthAuthenticated(makeProfile()),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] when user cancels Google picker',
      build: () {
        when(mockRepo.signInWithGoogle())
            .thenThrow(Exception('cancelled by user'));
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthUnauthenticated(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] on non-cancel error',
      build: () {
        when(mockRepo.signInWithGoogle())
            .thenThrow(Exception('network error'));
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthGoogleSignInRequested()),
      expect: () => [
        const AuthLoading(),
        isA<AuthFailure>(),
      ],
    );
  });

  // ── resend verification email ─────────────────────────────────────────────

  group('AuthVerificationEmailRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits AuthVerificationEmailSent on success',
      build: () {
        when(mockRepo.sendEmailVerification()).thenAnswer((_) => Future<void>.value());
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthVerificationEmailRequested()),
      expect: () => [const AuthVerificationEmailSent()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits AuthFailure when sendEmailVerification throws',
      build: () {
        when(mockRepo.sendEmailVerification())
            .thenThrow(Exception('too-many-requests'));
        return AuthBloc(authRepository: mockRepo);
      },
      act: (bloc) => bloc.add(const AuthVerificationEmailRequested()),
      expect: () => [isA<AuthFailure>()],
    );
  });
}
