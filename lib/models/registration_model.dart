import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Registration model representing a user's event registration
class RegistrationModel extends Equatable {
  final String id;
  final String eventId;
  final String clubId;
  final String userId;
  final String status; // "registered" or "waitlisted"
  final DateTime? registeredAt;

  const RegistrationModel({
    required this.id,
    required this.eventId,
    required this.clubId,
    required this.userId,
    required this.status,
    this.registeredAt,
  });

  /// Create RegistrationModel from Firestore document map
  factory RegistrationModel.fromMap(Map<String, dynamic> map, String documentId) {
    return RegistrationModel(
      id: documentId,
      eventId: map['eventId'] as String? ?? '',
      clubId: map['clubId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      status: map['status'] as String? ?? 'registered',
      registeredAt: map['registeredAt'] != null
          ? (map['registeredAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert RegistrationModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'clubId': clubId,
      'userId': userId,
      'status': status,
      'registeredAt': registeredAt != null
          ? Timestamp.fromDate(registeredAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create copy with updated fields
  RegistrationModel copyWith({
    String? id,
    String? eventId,
    String? clubId,
    String? userId,
    String? status,
    DateTime? registeredAt,
  }) {
    return RegistrationModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      clubId: clubId ?? this.clubId,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      registeredAt: registeredAt ?? this.registeredAt,
    );
  }

  @override
  List<Object?> get props => [id, eventId, clubId, userId, status, registeredAt];
}
