part of 'settings_cubit.dart';

abstract class SettingsState extends Equatable {
  const SettingsState();

  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {
  const SettingsInitial();
}

class SettingsLoaded extends SettingsState {
  const SettingsLoaded({required this.profile});
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

class SettingsSaving extends SettingsState {
  const SettingsSaving({required this.profile});
  final UserProfile profile;

  @override
  List<Object?> get props => [profile];
}

class SettingsError extends SettingsState {
  const SettingsError({required this.profile, required this.message});
  final UserProfile profile;
  final String message;

  @override
  List<Object?> get props => [profile, message];
}
