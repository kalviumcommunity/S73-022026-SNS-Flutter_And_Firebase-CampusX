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
  
  /// Type of request: "existing_club" or "new_club"
  final String? requestType;
  
  /// ID of existing club (for existing_club requests)
  final String? targetClubId;
  
  /// Name of new club (for new_club requests)
  final String? newClubName;
  
  /// Description of new club (for new_club requests)
  final String? newClubDescription;

  RoleRequestModel({
    required this.id,
    required this.userId,
    required this.requestedRole,
    required this.currentRole,
    required this.status,
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
    this.requestType,
    this.targetClubId,
    this.newClubName,
    this.newClubDescription,
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
      requestType: map['requestType'] as String?,
      targetClubId: map['targetClubId'] as String?,
      newClubName: map['newClubName'] as String?,
      newClubDescription: map['newClubDescription'] as String?,
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
      'requestType': requestType,
      'targetClubId': targetClubId,
      'newClubName': newClubName,
      'newClubDescription': newClubDescription,
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
    String? requestType,
    String? targetClubId,
    String? newClubName,
    String? newClubDescription,
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
      requestType: requestType ?? this.requestType,
      targetClubId: targetClubId ?? this.targetClubId,
      newClubName: newClubName ?? this.newClubName,
      newClubDescription: newClubDescription ?? this.newClubDescription,
    );
  }
}
