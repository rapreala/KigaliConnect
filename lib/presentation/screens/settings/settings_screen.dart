import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/config/theme.dart';
import 'package:kigali_connect/presentation/blocs/auth/auth_bloc.dart';
import 'package:kigali_connect/presentation/blocs/settings/settings_cubit.dart';
import 'package:kigali_connect/presentation/blocs/settings/theme_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Load profile into SettingsCubit whenever auth state is authenticated
    final authState = context.watch<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<SettingsCubit>().loadProfile(authState.profile);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          if (state is SettingsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          if (state is SettingsInitial) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = switch (state) {
            SettingsLoaded()  => state.profile,
            SettingsSaving()  => state.profile,
            SettingsError()   => state.profile,
            _                 => null,
          };

          if (profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final isSaving = state is SettingsSaving;
          final isDarkMode =
              context.watch<ThemeCubit>().state == ThemeMode.dark;

          return ListView(
            children: [
              // Profile section
              Padding(
                padding: const EdgeInsets.all(AppSpacing.p16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        profile.displayName.isNotEmpty
                            ? profile.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.p16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          profile.email,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(),

              // Notifications toggle
              SwitchListTile(
                title: const Text('Enable Notifications'),
                subtitle: const Text('Receive updates about new places'),
                value: profile.notificationsEnabled,
                activeThumbColor: AppColors.primary,
                onChanged: isSaving
                    ? null
                    : (value) => context
                        .read<SettingsCubit>()
                        .toggleNotifications(uid: profile.uid, enabled: value),
              ),

              const Divider(),

              // Dark mode toggle
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode_outlined),
                title: const Text('Dark Mode'),
                subtitle: Text(isDarkMode ? 'Dark theme active' : 'Light theme active'),
                value: isDarkMode,
                activeThumbColor: AppColors.primary,
                onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
              ),

              const Divider(),

              // Sign out
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => context
                    .read<AuthBloc>()
                    .add(const AuthSignOutRequested()),
              ),
            ],
          );
        },
      ),
    );
  }
}
