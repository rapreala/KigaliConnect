import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final DateTime createdAt;
  final bool notificationsEnabled;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.createdAt,
    this.notificationsEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid':                   uid,
      'email':                 email,
      'displayName':           displayName,
      'createdAt':             Timestamp.fromDate(createdAt),
      'notificationsEnabled':  notificationsEnabled,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid:                  json['uid'] as String,
      email:                json['email'] as String,
      displayName:          json['displayName'] as String,
      createdAt:            (json['createdAt'] as Timestamp).toDate(),
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? false,
    );
  }

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    DateTime? createdAt,
    bool? notificationsEnabled,
  }) {
    return UserProfile(
      uid:                  uid                  ?? this.uid,
      email:                email                ?? this.email,
      displayName:          displayName          ?? this.displayName,
      createdAt:            createdAt            ?? this.createdAt,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.uid                  == uid &&
        other.email                == email &&
        other.displayName          == displayName &&
        other.notificationsEnabled == notificationsEnabled;
  }

  @override
  int get hashCode => Object.hash(uid, email, displayName, notificationsEnabled);

  @override
  String toString() =>
      'UserProfile(uid: $uid, email: $email, displayName: $displayName)';
}
