import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:kigali_connect/presentation/widgets/common/app_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Poll every 3 seconds — when the user clicks the link in their email
    // Firebase reloads the user and authStateChanges fires automatically.
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await user.reload();
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null && refreshed.emailVerified && mounted) {
        // Re-trigger auth check so AuthGate routes to the app shell.
        context.read<AuthBloc>().add(const AuthCheckRequested());
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthVerificationEmailSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification email sent!')),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          return SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.p24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.mark_email_unread_outlined,
                      size: 80,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: AppSpacing.p24),
                    Text(
                      'Verify Your Email',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.p12),
                    Text(
                      'We sent a verification link to your email address. '
                      'Please check your inbox and click the link to continue.',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.p8),
                    Text(
                      'This screen will update automatically once verified.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.p32),
                    AppButton(
                      label: 'Resend Email',
                      isLoading: isLoading,
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthVerificationEmailRequested()),
                    ),
                    const SizedBox(height: AppSpacing.p16),
                    AppButton(
                      label: 'Sign Out',
                      variant: AppButtonVariant.secondary,
                      onPressed: isLoading
                          ? null
                          : () => context
                              .read<AuthBloc>()
                              .add(const AuthSignOutRequested()),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
