import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'notification_preferences.dart';

/// User model representing a user in the app with club-scoped roles
class UserModel extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  
  /// List of club IDs where user has admin privileges
  final List<String> adminClubs;
  
  /// List of club IDs the user has joined
  final List<String> joinedClubs;
  
  /// Profile fields
  final String? bio;
  final String? phone;
  final String? profilePhotoUrl;
  
  /// Privacy settings
  final bool showEmail;
  final bool showPhone;
  
  /// FCM token for push notifications
  final String? fcmToken;
  final DateTime? fcmTokenUpdatedAt;
  
  /// Notification preferences
  final NotificationPreferences notificationPreferences;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.adminClubs = const [],
    this.joinedClubs = const [],
    this.bio,
    this.phone,
    this.profilePhotoUrl,
    this.showEmail = true,
    this.showPhone = true,
    this.fcmToken,
    this.fcmTokenUpdatedAt,
    this.notificationPreferences = const NotificationPreferences(),
  });

  /// Create UserModel from Firestore document map
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      adminClubs: map['adminClubs'] != null
          ? List<String>.from(map['adminClubs'] as List)
          : [],
      joinedClubs: map['joinedClubs'] != null
          ? List<String>.from(map['joinedClubs'] as List)
          : [],
      bio: map['bio'] as String?,
      phone: map['phone'] as String?,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      showEmail: map['showEmail'] as bool? ?? true,
      showPhone: map['showPhone'] as bool? ?? true,
      fcmToken: map['fcmToken'] as String?,
      fcmTokenUpdatedAt: map['fcmTokenUpdatedAt'] != null
          ? (map['fcmTokenUpdatedAt'] as Timestamp).toDate()
          : null,
      notificationPreferences: NotificationPreferences.fromMap(
        map['notificationPreferences'] as Map<String, dynamic>?,
      ),
    );
  }

  /// Convert UserModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'adminClubs': adminClubs,
      'joinedClubs': joinedClubs,
      'createdAt': createdAt != null 
          ? Timestamp.fromDate(createdAt!) 
          : FieldValue.serverTimestamp(),
      'bio': bio,
      'phone': phone,
      'profilePhotoUrl': profilePhotoUrl,
      'showEmail': showEmail,
      'showPhone': showPhone,
      'fcmToken': fcmToken,
      'fcmTokenUpdatedAt': fcmTokenUpdatedAt != null
          ? Timestamp.fromDate(fcmTokenUpdatedAt!)
          : null,
      'notificationPreferences': notificationPreferences.toMap(),
    };
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    List<String>? adminClubs,
    List<String>? joinedClubs,
    String? bio,
    String? phone,
    String? profilePhotoUrl,
    bool? showEmail,
    bool? showPhone,
    String? fcmToken,
    DateTime? fcmTokenUpdatedAt,
    NotificationPreferences? notificationPreferences,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      adminClubs: adminClubs ?? this.adminClubs,
      joinedClubs: joinedClubs ?? this.joinedClubs,
      bio: bio ?? this.bio,
      phone: phone ?? this.phone,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      showEmail: showEmail ?? this.showEmail,
      showPhone: showPhone ?? this.showPhone,
      fcmToken: fcmToken ?? this.fcmToken,
      fcmTokenUpdatedAt: fcmTokenUpdatedAt ?? this.fcmTokenUpdatedAt,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        name,
        email,
        role,
        createdAt,
        adminClubs,
        joinedClubs,
        bio,
        phone,
        profilePhotoUrl,
        showEmail,
        showPhone,
        fcmToken,
        fcmTokenUpdatedAt,
        notificationPreferences,
      ];

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, '
        'createdAt: $createdAt, adminClubs: $adminClubs, joinedClubs: $joinedClubs, '
        'bio: $bio, phone: $phone, profilePhotoUrl: $profilePhotoUrl, '
        'showEmail: $showEmail, showPhone: $showPhone, fcmToken: ${fcmToken != null ? "[SET]" : "null"}, '
        'fcmTokenUpdatedAt: $fcmTokenUpdatedAt, notificationPreferences: $notificationPreferences)';
  }
}
