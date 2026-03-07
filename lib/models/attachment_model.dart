import 'package:equatable/equatable.dart';

/// Model for file attachments (images, PDFs, etc.)
class AttachmentModel extends Equatable {
  final String url;
  final String name;
  final String type; // image, pdf, document, etc.
  final int size; // in bytes
  final DateTime uploadedAt;

  const AttachmentModel({
    required this.url,
    required this.name,
    required this.type,
    required this.size,
    required this.uploadedAt,
  });

  /// Create AttachmentModel from map
  factory AttachmentModel.fromMap(Map<String, dynamic> map) {
    return AttachmentModel(
      url: map['url'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'unknown',
      size: map['size'] as int? ?? 0,
      uploadedAt: map['uploadedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['uploadedAt'] as int)
          : DateTime.now(),
    );
  }

  /// Convert AttachmentModel to map
  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'name': name,
      'type': type,
      'size': size,
      'uploadedAt': uploadedAt.millisecondsSinceEpoch,
    };
  }

  /// Get file extension from name
  String get extension {
    if (name.contains('.')) {
      return name.split('.').last.toLowerCase();
    }
    return '';
  }

  /// Check if attachment is an image
  bool get isImage {
    return type == 'image' || ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
  }

  /// Check if attachment is a PDF
  bool get isPdf {
    return type == 'pdf' || extension == 'pdf';
  }

  /// Get formatted file size
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  List<Object?> get props => [url, name, type, size, uploadedAt];

  @override
  String toString() {
    return 'AttachmentModel(name: $name, type: $type, size: $formattedSize, url: $url)';
  }
}
