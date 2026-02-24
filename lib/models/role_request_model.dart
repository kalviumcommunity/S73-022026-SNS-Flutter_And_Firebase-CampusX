import 'package:cloud_firestore/cloud_firestore.dart';

class RoleRequestModel {
  final String id;
  final String userId;
  final String requestedRole;
  final String currentRole;
  final String status;
  final Timestamp requestedAt;
  final String? reviewedBy;
  final Timestamp? reviewedAt;

  RoleRequestModel({
    required this.id,
    required this.userId,
    required this.requestedRole,
    required this.currentRole,
    required this.status,
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  factory RoleRequestModel.fromMap(Map<String, dynamic> map) {
    return RoleRequestModel(
      id: map['id'] as String,
      userId: map['userId'] as String,
      requestedRole: map['requestedRole'] as String,
      currentRole: map['currentRole'] as String,
      status: map['status'] as String,
      requestedAt: map['requestedAt'] as Timestamp,
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: map['reviewedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'requestedRole': requestedRole,
      'currentRole': currentRole,
      'status': status,
      'requestedAt': requestedAt,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
    };
  }

  RoleRequestModel copyWith({
    String? id,
    String? userId,
    String? requestedRole,
    String? currentRole,
    String? status,
    Timestamp? requestedAt,
    String? reviewedBy,
    Timestamp? reviewedAt,
  }) {
    return RoleRequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      requestedRole: requestedRole ?? this.requestedRole,
      currentRole: currentRole ?? this.currentRole,
      status: status ?? this.status,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}
