import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/attachment_model.dart';

/// Widget for picking and displaying file attachments
class AttachmentPickerWidget extends StatefulWidget {
  final List<AttachmentModel> initialAttachments;
  final Function(List<File>) onFilesSelected;
  final Function(AttachmentModel)? onAttachmentRemoved;
  final int maxFiles;
  final bool allowMultiple;

  const AttachmentPickerWidget({
    super.key,
    this.initialAttachments = const [],
    required this.onFilesSelected,
    this.onAttachmentRemoved,
    this.maxFiles = 5,
    this.allowMultiple = true,
  });

  @override
  State<AttachmentPickerWidget> createState() => _AttachmentPickerWidgetState();
}

class _AttachmentPickerWidgetState extends State<AttachmentPickerWidget> {
  final List<File> _selectedFiles = [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalAttachments = widget.initialAttachments.length + _selectedFiles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Display existing attachments
        if (widget.initialAttachments.isNotEmpty) ...[
          Text(
            'Current Attachments',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...widget.initialAttachments.map(
            (attachment) => _buildAttachmentCard(
              theme,
              attachment: attachment,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Display newly selected files
        if (_selectedFiles.isNotEmpty) ...[
          Text(
            'New Attachments',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ..._selectedFiles.asMap().entries.map(
                (entry) => _buildAttachmentCard(
                  theme,
                  file: entry.value,
                  fileIndex: entry.key,
                ),
              ),
          const SizedBox(height: 16),
        ],

        // Add attachment button
        if (totalAttachments < widget.maxFiles)
          OutlinedButton.icon(
            onPressed: _pickFiles,
            icon: const Icon(Icons.attach_file),
            label: Text(
              widget.allowMultiple
                  ? 'Add Attachments (${widget.maxFiles - totalAttachments} remaining)'
                  : 'Add Attachment',
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentCard(
    ThemeData theme, {
    AttachmentModel? attachment,
    File? file,
    int? fileIndex,
  }) {
    final isExisting = attachment != null;
    final fileName = isExisting ? attachment.name : file!.path.split('/').last;
    final fileSize = isExisting
        ? attachment.formattedSize
        : _formatFileSize(file!.lengthSync());
    final isImage = isExisting
        ? attachment.isImage
        : _isImageFile(fileName);
    final isPdf = isExisting ? attachment.isPdf : _isPdfFile(fileName);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(
            isImage
                ? Icons.image
                : isPdf
                    ? Icons.picture_as_pdf
                    : Icons.insert_drive_file,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(fileSize),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (isExisting) {
              widget.onAttachmentRemoved?.call(attachment);
            } else {
              _removeFile(fileIndex!);
            }
          },
        ),
        // Show full-size image on tap if it's an image
        onTap: isImage && isExisting
            ? () => _showImagePreview(attachment.url)
            : null,
      ),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: widget.allowMultiple,
        type: FileType.custom,
        allowedExtensions: [
          'jpg', 'jpeg', 'png', 'gif', 'webp', // Images
          'pdf', // PDFs
          'doc', 'docx', 'txt', 'rtf', // Documents
        ],
      );

      if (result != null) {
        final totalAttachments =
            widget.initialAttachments.length + _selectedFiles.length;
        final remainingSlots = widget.maxFiles - totalAttachments;

        final newFiles = result.files
            .take(remainingSlots)
            .map((file) => File(file.path!))
            .toList();

        // Validate file sizes
        final validFiles = <File>[];
        for (final file in newFiles) {
          final fileSize = await file.length();
          final isImage = _isImageFile(file.path);
          final maxSize = isImage ? 5 * 1024 * 1024 : 10 * 1024 * 1024; // 5MB for images, 10MB for others

          if (fileSize > maxSize) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${file.path.split('/').last} exceeds ${isImage ? '5MB' : '10MB'} limit',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            validFiles.add(file);
          }
        }

        if (validFiles.isNotEmpty) {
          setState(() {
            _selectedFiles.addAll(validFiles);
          });
          widget.onFilesSelected(_selectedFiles);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
    });
    widget.onFilesSelected(_selectedFiles);
  }

  void _showImagePreview(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }

  bool _isImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  bool _isPdfFile(String fileName) {
    return fileName.toLowerCase().endsWith('.pdf');
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
