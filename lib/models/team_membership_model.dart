import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Team membership model representing a user's membership/request to join a team
class TeamMembershipModel extends Equatable {
  final String id;
  final String teamId;
  final String clubId;
  final String userId;
  
  /// Role within the team (e.g., "member", "head")
  final String role;
  
  /// Membership status (e.g., "pending", "approved", "rejected")
  final String status;
  
  /// Interview status (e.g., "not_scheduled", "scheduled", "completed")
  final String interviewStatus;
  
  final Timestamp requestedAt;
  
  /// ID of the admin who reviewed the request
  final String? reviewedBy;
  
  /// Timestamp when the request was reviewed
  final Timestamp? reviewedAt;

  const TeamMembershipModel({
    required this.id,
    required this.teamId,
    required this.clubId,
    required this.userId,
    this.role = 'member',
    this.status = 'pending',
    this.interviewStatus = 'not_scheduled',
    required this.requestedAt,
    this.reviewedBy,
    this.reviewedAt,
  });

  /// Create TeamMembershipModel from Firestore document map
  factory TeamMembershipModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TeamMembershipModel(
      id: documentId,
      teamId: map['teamId'] as String? ?? '',
      clubId: map['clubId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      role: map['role'] as String? ?? 'member',
      status: map['status'] as String? ?? 'pending',
      interviewStatus: map['interviewStatus'] as String? ?? 'not_scheduled',
      requestedAt: map['requestedAt'] as Timestamp? ?? Timestamp.now(),
      reviewedBy: map['reviewedBy'] as String?,
      reviewedAt: map['reviewedAt'] as Timestamp?,
    );
  }

  /// Convert TeamMembershipModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'clubId': clubId,
      'userId': userId,
      'role': role,
      'status': status,
      'interviewStatus': interviewStatus,
      'requestedAt': requestedAt,
      'reviewedBy': reviewedBy,
      'reviewedAt': reviewedAt,
    };
  }

  /// Create a copy of TeamMembershipModel with updated fields
  TeamMembershipModel copyWith({
    String? id,
    String? teamId,
    String? clubId,
    String? userId,
    String? role,
    String? status,
    String? interviewStatus,
    Timestamp? requestedAt,
    String? reviewedBy,
    Timestamp? reviewedAt,
  }) {
    return TeamMembershipModel(
      id: id ?? this.id,
      teamId: teamId ?? this.teamId,
      clubId: clubId ?? this.clubId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      interviewStatus: interviewStatus ?? this.interviewStatus,
      requestedAt: requestedAt ?? this.requestedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        teamId,
        clubId,
        userId,
        role,
        status,
        interviewStatus,
        requestedAt,
        reviewedBy,
        reviewedAt,
      ];

  @override
  String toString() {
    return 'TeamMembershipModel(id: $id, teamId: $teamId, clubId: $clubId, '
        'userId: $userId, role: $role, status: $status, '
        'interviewStatus: $interviewStatus, requestedAt: $requestedAt, '
        'reviewedBy: $reviewedBy, reviewedAt: $reviewedAt)';
  }
}
