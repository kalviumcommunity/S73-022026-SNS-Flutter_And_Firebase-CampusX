import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
    this.adminClubs = const [],
    this.joinedClubs = const [],
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
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      adminClubs: adminClubs ?? this.adminClubs,
      joinedClubs: joinedClubs ?? this.joinedClubs,
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
      ];

  @override
  String toString() {
    return 'UserModel(uid: $uid, name: $name, email: $email, role: $role, '
        'createdAt: $createdAt, adminClubs: $adminClubs, joinedClubs: $joinedClubs)';
  }
}
