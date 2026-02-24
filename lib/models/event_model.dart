import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Event model representing an event in the app
class EventModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final String clubId;
  final String createdBy;
  final DateTime date;
  final String location;
  final int capacity;
  final DateTime? createdAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.clubId,
    required this.createdBy,
    required this.date,
    required this.location,
    required this.capacity,
    this.createdAt,
  });

  /// Create EventModel from Firestore document map
  factory EventModel.fromMap(Map<String, dynamic> map, String documentId) {
    return EventModel(
      id: documentId,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      clubId: map['clubId'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      location: map['location'] as String? ?? '',
      capacity: map['capacity'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert EventModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'clubId': clubId,
      'createdBy': createdBy,
      'date': Timestamp.fromDate(date),
      'location': location,
      'capacity': capacity,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy of EventModel with updated fields
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? clubId,
    String? createdBy,
    DateTime? date,
    String? location,
    int? capacity,
    DateTime? createdAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      clubId: clubId ?? this.clubId,
      createdBy: createdBy ?? this.createdBy,
      date: date ?? this.date,
      location: location ?? this.location,
      capacity: capacity ?? this.capacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        clubId,
        createdBy,
        date,
        location,
        capacity,
        createdAt,
      ];

  @override
  String toString() {
    return 'EventModel(id: $id, title: $title, description: $description, clubId: $clubId, createdBy: $createdBy, date: $date, location: $location, capacity: $capacity, createdAt: $createdAt)';
  }
}
