import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kigali_connect/domain/models/user_profile.dart';

part 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const SettingsInitial());

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  void loadProfile(UserProfile profile) {
    emit(SettingsLoaded(profile: profile));
  }

  Future<void> toggleNotifications({
    required String uid,
    required bool enabled,
  }) async {
    final current = state;
    if (current is! SettingsLoaded) return;

    emit(SettingsSaving(profile: current.profile));
    try {
      await _users.doc(uid).update({'notificationsEnabled': enabled});
      emit(SettingsLoaded(
        profile: current.profile.copyWith(notificationsEnabled: enabled),
      ));
    } catch (e) {
      emit(SettingsError(
        profile: current.profile,
        message: e.toString(),
      ));
    }
  }
}
