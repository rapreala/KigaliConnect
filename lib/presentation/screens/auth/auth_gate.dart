import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:kigali_connect/presentation/screens/auth/email_verification_screen.dart';
import 'package:kigali_connect/presentation/screens/auth/login_screen.dart';
import 'package:kigali_connect/presentation/widgets/common/loading_overlay.dart';

/// Decides which top-level screen to show based on [AuthState].
/// Will be wired to the navigation shell once AppShell is built.
class AuthGate extends StatefulWidget {
  const AuthGate({required this.authenticatedChild, super.key});

  /// The widget to show when the user is fully authenticated.
  final Widget authenticatedChild;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is AuthInitial || state is AuthLoading) {
          return const Scaffold(
            body: LoadingOverlay(isLoading: true, child: SizedBox.expand()),
          );
        }
        if (state is AuthEmailNotVerified) {
          return const EmailVerificationScreen();
        }
        if (state is AuthAuthenticated) {
          return widget.authenticatedChild;
        }
        // AuthUnauthenticated or AuthFailure
        return const LoginScreen();
      },
    );
  }
}
