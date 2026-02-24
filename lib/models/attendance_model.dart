import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Attendance model representing a user's attendance at an event
class AttendanceModel extends Equatable {
  final String id;
  final String eventId;
  final String userId;
  final String clubId;
  final String status; // "present" or "absent"
  final String markedBy; // Admin ID who marked the attendance
  final DateTime? markedAt;

  const AttendanceModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.clubId,
    required this.status,
    required this.markedBy,
    this.markedAt,
  });

  /// Create AttendanceModel from Firestore document map
  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      eventId: map['eventId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      clubId: map['clubId'] as String? ?? '',
      status: map['status'] as String? ?? 'absent',
      markedBy: map['markedBy'] as String? ?? '',
      markedAt: map['markedAt'] != null
          ? (map['markedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert AttendanceModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'clubId': clubId,
      'status': status,
      'markedBy': markedBy,
      'markedAt': markedAt != null
          ? Timestamp.fromDate(markedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create copy with updated fields
  AttendanceModel copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? clubId,
    String? status,
    String? markedBy,
    DateTime? markedAt,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      clubId: clubId ?? this.clubId,
      status: status ?? this.status,
      markedBy: markedBy ?? this.markedBy,
      markedAt: markedAt ?? this.markedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        userId,
        clubId,
        status,
        markedBy,
        markedAt,
      ];
}
