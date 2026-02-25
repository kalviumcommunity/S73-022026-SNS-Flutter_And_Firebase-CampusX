import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Team model representing a team within a club
class TeamModel extends Equatable {
  final String id;
  final String clubId;
  final String name;
  final String description;
  
  /// List of user IDs who head this team
  final List<String> headIds;
  
  final int memberCount;
  final bool isActive;
  final String createdBy;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const TeamModel({
    required this.id,
    required this.clubId,
    required this.name,
    required this.description,
    this.headIds = const [],
    this.memberCount = 0,
    this.isActive = true,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create TeamModel from Firestore document map
  factory TeamModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TeamModel(
      id: documentId,
      clubId: map['clubId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      headIds: map['headIds'] != null
          ? List<String>.from(map['headIds'] as List)
          : [],
      memberCount: map['memberCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Convert TeamModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'clubId': clubId,
      'name': name,
      'description': description,
      'headIds': headIds,
      'memberCount': memberCount,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of TeamModel with updated fields
  TeamModel copyWith({
    String? id,
    String? clubId,
    String? name,
    String? description,
    List<String>? headIds,
    int? memberCount,
    bool? isActive,
    String? createdBy,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return TeamModel(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      description: description ?? this.description,
      headIds: headIds ?? this.headIds,
      memberCount: memberCount ?? this.memberCount,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clubId,
        name,
        description,
        headIds,
        memberCount,
        isActive,
        createdBy,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'TeamModel(id: $id, clubId: $clubId, name: $name, '
        'description: $description, headIds: $headIds, memberCount: $memberCount, '
        'isActive: $isActive, createdBy: $createdBy, createdAt: $createdAt, '
        'updatedAt: $updatedAt)';
  }
}
