import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/club_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/team_service.dart';
import '../../../models/announcement_model.dart';
import '../../../models/attachment_model.dart';
import '../../../models/club_model.dart';
import '../../../models/team_model.dart';
import '../../../shared/widgets/attachment_picker_widget.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/announcement_provider.dart';

/// Provider for clubs where user is admin
final userAdminClubsForAnnouncementProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final clubService = ClubService();
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return clubService.getClubsByAdmin(user.uid);
});

/// Provider for teams by club
final teamsByClubForAnnouncementProvider = StreamProvider.family<List<TeamModel>, String>((ref, clubId) {
  final teamService = TeamService();
  return teamService.getTeamsByClub(clubId);
});

/// Screen for creating a new announcement
class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  ConsumerState<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends ConsumerState<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String? _selectedClubId;
  String? _selectedTeamId;
  bool _isPinned = false;
  final List<File> _selectedFiles = [];
  bool _isUploadingAttachments = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationState = ref.watch(announcementOperationsProvider);
    final currentUser = ref.watch(authProvider).user;
    final adminClubsAsync = ref.watch(userAdminClubsForAnnouncementProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Post Announcement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
            color: Colors.white,
            shadows: [
              Shadow(
                offset: Offset(0, 1),
                blurRadius: 3.0,
                color: Colors.black38,
              ),
            ],
          ),
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6366F1),
                Color(0xFF8B5CF6),
                Color(0xFF06B6D4),
              ],
            ),
          ),
        ),
      ),
      body: operationState.isLoading || _isUploadingAttachments
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_isUploadingAttachments 
                    ? 'Uploading attachments...'
                    : 'Posting announcement...'),
                ],
              ),
            )
          : adminClubsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error: $error'),
                  ],
                ),
              ),
              data: (clubs) {
                if (clubs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        const Text(
                          'You are not assigned as admin to any club',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Please contact the college admin',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Auto-select first club if not already selected
                if (_selectedClubId == null && clubs.isNotEmpty) {
                  _selectedClubId = clubs.first.id;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        Text(
                          'Create Announcement',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share important updates with your club members',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Club Selection
                        if (clubs.length == 1)
                          InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Club',
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              clubs.first.name,
                              style: theme.textTheme.bodyLarge,
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedClubId,
                            decoration: const InputDecoration(
                              labelText: 'Select Club',
                              prefixIcon: Icon(Icons.group),
                              border: OutlineInputBorder(),
                            ),
                            items: clubs.map((club) {
                              return DropdownMenuItem<String>(
                                value: club.id,
                                child: Text(club.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedClubId = value;
                                _selectedTeamId = null; // Reset team when club changes
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a club';
                              }
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),

                        // Team Selection (optional)
                        if (_selectedClubId != null)
                          Consumer(
                            builder: (context, ref, child) {
                              final teamsAsync = ref.watch(teamsByClubForAnnouncementProvider(_selectedClubId!));
                              
                              return teamsAsync.when(
                                loading: () => const LinearProgressIndicator(),
                                error: (error, stack) => Text(
                                  'Error loading teams: $error',
                                  style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                                ),
                                data: (teams) {
                                  if (teams.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      DropdownButtonFormField<String>(
                                        value: _selectedTeamId,
                                        decoration: const InputDecoration(
                                          labelText: 'Team (Optional)',
                                          prefixIcon: Icon(Icons.groups_2),
                                          border: OutlineInputBorder(),
                                          helperText: 'Leave blank to announce to entire club',
                                        ),
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('All Teams (Entire Club)'),
                                          ),
                                          ...teams.map((team) {
                                            return DropdownMenuItem<String>(
                                              value: team.id,
                                              child: Text(team.name),
                                            );
                                          }),
                                        ],
                                        onChanged: (value) {
                                          setState(() {
                                            _selectedTeamId = value;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  );
                                },
                              );
                            },
                          ),

                        // Title Field
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Title',
                            hintText: 'Enter announcement title',
                            prefixIcon: Icon(Icons.title),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a title';
                            }
                            if (value.trim().length < 3) {
                              return 'Title must be at least 3 characters';
                            }
                            return null;
                          },
                          maxLength: 100,
                        ),
                        const SizedBox(height: 16),

                        // Content Field
                        TextFormField(
                          controller: _contentController,
                          decoration: const InputDecoration(
                            labelText: 'Content',
                            hintText: 'Enter announcement details',
                            prefixIcon: Icon(Icons.description),
                            border: OutlineInputBorder(),
                            alignLabelWithHint: true,
                          ),
                          maxLines: 8,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter content';
                            }
                            if (value.trim().length < 10) {
                              return 'Content must be at least 10 characters';
                            }
                            return null;
                          },
                          maxLength: 1000,
                        ),
                        const SizedBox(height: 24),

                        // Attachments
                        Text(
                          'Attachments (Optional)',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        AttachmentPickerWidget(
                          maxFiles: 5,
                          allowMultiple: true,
                          onFilesSelected: (files) {
                            setState(() {
                              _selectedFiles.clear();
                              _selectedFiles.addAll(files);
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Pin Checkbox
                        CheckboxListTile(
                          title: const Text('Pin this announcement'),
                          subtitle: const Text('Pinned announcements appear at the top'),
                          value: _isPinned,
                          onChanged: (value) {
                            setState(() {
                              _isPinned = value ?? false;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 24),

                        // Error Message
                        if (operationState.error != null)
                          Card(
                            color: theme.colorScheme.errorContainer,
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      operationState.error!,
                                      style: TextStyle(
                                        color: theme.colorScheme.onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Post Button
                        FilledButton.icon(
                          onPressed: operationState.isLoading
                              ? null
                              : () => _handlePostAnnouncement(context, currentUser?.uid),
                          icon: const Icon(Icons.send),
                          label: const Text('Post Announcement'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cancel Button
                        OutlinedButton.icon(
                          onPressed: operationState.isLoading
                              ? null
                              : () => context.pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _handlePostAnnouncement(BuildContext context, String? userId) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedClubId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a club'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Upload attachments if any (before creating announcement)
    final List<AttachmentModel> attachments = [];
    if (_selectedFiles.isNotEmpty) {
      setState(() {
        _isUploadingAttachments = true;
      });
      
      try {
        // Create a temporary announcement ID for storage path
        final tempAnnouncementId = DateTime.now().millisecondsSinceEpoch.toString();
        final storageService = StorageService();
        
        for (final file in _selectedFiles) {
          final attachment = await storageService.uploadAnnouncementAttachment(
            file: file,
            announcementId: tempAnnouncementId,
          );
          attachments.add(attachment);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploadingAttachments = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to upload attachments: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      } finally {
        if (mounted) {
          setState(() {
            _isUploadingAttachments = false;
          });
        }
      }
    }

    // Create announcement model
    final announcement = AnnouncementModel(
      id: '', // Will be generated by Firestore
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      attachments: attachments,
      clubId: _selectedClubId!,
      teamId: _selectedTeamId, // Optional team ID
      createdBy: userId,
      createdAt: DateTime.now(),
      isPinned: _isPinned,
      isActive: true,
    );

    // Create announcement using provider
    final announcementId = await ref
        .read(announcementOperationsProvider.notifier)
        .createAnnouncement(announcement, userId);

    if (context.mounted) {
      if (announcementId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Announcement posted successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Navigate back after short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (context.mounted) {
            context.pop();
          }
        });
      } else {
        // Error message already shown in state
        final operationState = ref.read(announcementOperationsProvider);
        if (operationState.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(operationState.error!),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }
}
