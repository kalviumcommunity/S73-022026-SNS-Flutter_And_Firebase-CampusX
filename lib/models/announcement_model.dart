import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import 'attachment_model.dart';

/// Model for announcements posted by club admins
class AnnouncementModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final List<AttachmentModel> attachments;
  final String clubId;
  final String? teamId; // Optional: announcement can be for specific team or entire club
  final String createdBy;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPinned;
  final bool isActive;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    this.attachments = const [],
    required this.clubId,
    this.teamId,
    required this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.isPinned = false,
    this.isActive = true,
  });

  /// Create AnnouncementModel from Firestore document
  factory AnnouncementModel.fromMap(Map<String, dynamic> map, String documentId) {
    final attachmentsList = map['attachments'] as List<dynamic>? ?? [];
    final attachments = attachmentsList
        .map((item) => AttachmentModel.fromMap(item as Map<String, dynamic>))
        .toList();

    return AnnouncementModel(
      id: documentId,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      attachments: attachments,
      clubId: map['clubId'] as String? ?? '',
      teamId: map['teamId'] as String?,
      createdBy: map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isPinned: map['isPinned'] as bool? ?? false,
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  /// Convert AnnouncementModel to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'clubId': clubId,
      'teamId': teamId,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isPinned': isPinned,
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields
  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? content,
    List<AttachmentModel>? attachments,
    String? clubId,
    String? teamId,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isActive,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      clubId: clubId ?? this.clubId,
      teamId: teamId ?? this.teamId,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        attachments,
        clubId,
        teamId,
        createdBy,
        createdAt,
        updatedAt,
        isPinned,
        isActive,
      ];

  @override
  String toString() {
    return 'AnnouncementModel(id: $id, title: $title, clubId: $clubId, '
        'createdBy: $createdBy, createdAt: $createdAt, isPinned: $isPinned)';
  }
}
