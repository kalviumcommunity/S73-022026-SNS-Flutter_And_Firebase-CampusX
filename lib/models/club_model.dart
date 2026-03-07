import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Club model representing a club in the system
class ClubModel extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String createdBy;
  final List<String> adminIds;
  final int memberCount;
  final bool isActive;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  const ClubModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.createdBy,
    this.adminIds = const [],
    this.memberCount = 0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create ClubModel from Firestore document map
  factory ClubModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ClubModel(
      id: documentId,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      logoUrl: map['logoUrl'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      adminIds: map['adminIds'] != null
          ? List<String>.from(map['adminIds'] as List)
          : [],
      memberCount: map['memberCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      updatedAt: map['updatedAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  /// Convert ClubModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'createdBy': createdBy,
      'adminIds': adminIds,
      'memberCount': memberCount,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of ClubModel with updated fields
  ClubModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? createdBy,
    List<String>? adminIds,
    int? memberCount,
    bool? isActive,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return ClubModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      createdBy: createdBy ?? this.createdBy,
      adminIds: adminIds ?? this.adminIds,
      memberCount: memberCount ?? this.memberCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        logoUrl,
        createdBy,
        adminIds,
        memberCount,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'ClubModel(id: $id, name: $name, description: $description, '
        'createdBy: $createdBy, adminIds: $adminIds, memberCount: $memberCount, '
        'isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
