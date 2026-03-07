import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

import '../../models/attachment_model.dart';

/// Service for handling Firebase Storage file operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a club logo
  /// Returns the download URL of the uploaded file
  Future<String> uploadClubLogo({
    required File file,
    required String clubId,
    void Function(double)? onProgress,
  }) async {
    try {
      // Delete existing logo if any
      await _deleteFileIfExists('clubs/logos/$clubId');

      final extension = path.extension(file.path);
      final filePath = 'clubs/logos/$clubId/logo$extension';
      
      return await _uploadFile(
        file: file,
        path: filePath,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload club logo: $e');
    }
  }

  /// Delete a club logo
  Future<void> deleteClubLogo(String clubId) async {
    try {
      await _deleteFileIfExists('clubs/logos/$clubId');
    } catch (e) {
      throw Exception('Failed to delete club logo: $e');
    }
  }

  /// Upload an event banner image
  /// Returns the download URL of the uploaded file
  Future<String> uploadEventImage({
    required File file,
    required String eventId,
    void Function(double)? onProgress,
  }) async {
    try {
      // Delete existing image if any
      await _deleteFileIfExists('events/images/$eventId');

      final extension = path.extension(file.path);
      final filePath = 'events/images/$eventId/banner$extension';
      
      return await _uploadFile(
        file: file,
        path: filePath,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload event image: $e');
    }
  }

  /// Delete an event banner image
  Future<void> deleteEventImage(String eventId) async {
    try {
      await _deleteFileIfExists('events/images/$eventId');
    } catch (e) {
      throw Exception('Failed to delete event image: $e');
    }
  }

  /// Upload an announcement attachment
  /// Returns an AttachmentModel with file metadata
  Future<AttachmentModel> uploadAnnouncementAttachment({
    required File file,
    required String announcementId,
    void Function(double)? onProgress,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'announcements/attachments/$announcementId/${timestamp}_$fileName';
      
      final downloadUrl = await _uploadFile(
        file: file,
        path: filePath,
        onProgress: onProgress,
      );

      // Get file metadata
      final fileStats = await file.stat();
      final fileType = _getFileType(fileName);

      return AttachmentModel(
        url: downloadUrl,
        name: fileName,
        type: fileType,
        size: fileStats.size,
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to upload announcement attachment: $e');
    }
  }

  /// Delete an announcement attachment by URL
  Future<void> deleteAnnouncementAttachment(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete announcement attachment: $e');
    }
  }

  /// Upload a user profile photo
  /// Returns the download URL of the uploaded file
  Future<String> uploadProfilePhoto({
    required File file,
    required String userId,
    void Function(double)? onProgress,
  }) async {
    try {
      // Delete existing photo if any
      await _deleteFileIfExists('users/profiles/$userId');

      final extension = path.extension(file.path);
      final filePath = 'users/profiles/$userId/photo$extension';
      
      return await _uploadFile(
        file: file,
        path: filePath,
        onProgress: onProgress,
      );
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Delete a user profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      await _deleteFileIfExists('users/profiles/$userId');
    } catch (e) {
      throw Exception('Failed to delete profile photo: $e');
    }
  }

  /// Generic file upload method
  Future<String> _uploadFile({
    required File file,
    required String path,
    void Function(double)? onProgress,
  }) async {
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(file);

    // Track upload progress if callback provided
    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  /// Delete all files in a directory if they exist
  Future<void> _deleteFileIfExists(String directoryPath) async {
    try {
      final ref = _storage.ref().child(directoryPath);
      final listResult = await ref.listAll();
      
      // Delete all files in the directory
      for (final item in listResult.items) {
        await item.delete();
      }
      
      // Delete all subdirectories recursively
      for (final prefix in listResult.prefixes) {
        await _deleteFileIfExists(prefix.fullPath);
      }
    } catch (e) {
      // Directory might not exist, which is fine
      if (!e.toString().contains('object-not-found')) {
        rethrow;
      }
    }
  }

  /// Determine file type from extension
  String _getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'].contains(extension)) {
      return 'image';
    } else if (extension == '.pdf') {
      return 'pdf';
    } else if (['.doc', '.docx', '.txt', '.rtf'].contains(extension)) {
      return 'document';
    } else {
      return 'unknown';
    }
  }

  /// Validate file size (in bytes)
  /// Default max: 5MB for images, 10MB for PDFs/documents
  bool validateFileSize(File file, {int? maxSizeBytes}) {
    final fileSize = file.lengthSync();
    final extension = path.extension(file.path).toLowerCase();
    
    final defaultMax = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp']
            .contains(extension)
        ? 5 * 1024 * 1024 // 5MB for images
        : 10 * 1024 * 1024; // 10MB for other files
    
    final maxSize = maxSizeBytes ?? defaultMax;
    return fileSize <= maxSize;
  }

  /// Validate file type
  /// Allowed types: images, PDFs, documents
  bool validateFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();
    const allowedExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', // Images
      '.pdf', // PDFs
      '.doc', '.docx', '.txt', '.rtf', // Documents
    ];
    return allowedExtensions.contains(extension);
  }

  /// Get file size in human-readable format
  String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
