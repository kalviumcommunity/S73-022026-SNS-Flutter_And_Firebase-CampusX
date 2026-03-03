import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/team_service.dart';
import '../../../models/announcement_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/announcement_provider.dart';

class AnnouncementsListScreen extends ConsumerWidget {
  final String clubId;

  const AnnouncementsListScreen({
    super.key,
    required this.clubId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final announcementsAsync = ref.watch(announcementsByClubProvider(clubId));
    final currentUser = ref.watch(currentUserProvider);
    final isClubAdmin = currentUser?.role == 'club_admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        actions: [
          if (isClubAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Create Announcement',
              onPressed: () => context.push('/create-announcement'),
            ),
        ],
      ),
      body: announcementsAsync.when(
        data: (announcements) {
          if (announcements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.campaign_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements yet',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isClubAdmin
                        ? 'Tap + to create your first announcement'
                        : 'Check back later for updates',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          }

          // Separate pinned and regular announcements
          final pinnedAnnouncements = announcements.where((a) => a.isPinned).toList();
          final regularAnnouncements = announcements.where((a) => !a.isPinned).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Pinned Announcements Section
              if (pinnedAnnouncements.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.push_pin, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Pinned Announcements',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...pinnedAnnouncements.map((announcement) => _AnnouncementCard(
                      announcement: announcement,
                      clubId: clubId,
                      isClubAdmin: isClubAdmin,
                      isPinned: true,
                    )),
                const SizedBox(height: 24),
              ],

              // Regular Announcements Section
              if (regularAnnouncements.isNotEmpty) ...[
                if (pinnedAnnouncements.isNotEmpty)
                  Row(
                    children: [
                      Icon(Icons.announcement_outlined, size: 20, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 8),
                      Text(
                        'Recent Announcements',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                if (pinnedAnnouncements.isNotEmpty) const SizedBox(height: 12),
                ...regularAnnouncements.map((announcement) => _AnnouncementCard(
                      announcement: announcement,
                      clubId: clubId,
                      isClubAdmin: isClubAdmin,
                      isPinned: false,
                    )),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text(
                'Error loading announcements',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends ConsumerWidget {
  final AnnouncementModel announcement;
  final String clubId;
  final bool isClubAdmin;
  final bool isPinned;

  const _AnnouncementCard({
    required this.announcement,
    required this.clubId,
    required this.isClubAdmin,
    required this.isPinned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPinned ? 3 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPinned
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAnnouncementDetails(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with pin icon and menu
              Row(
                children: [
                  if (isPinned) ...[
                    Icon(
                      Icons.push_pin,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isClubAdmin)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) => _handleMenuAction(context, ref, value),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(
                                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(isPinned ? 'Unpin' : 'Pin'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Content preview (truncated)
              Text(
                announcement.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Footer with metadata
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  // Date
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(announcement.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),

                  // Team (if targeted)
                  if (announcement.teamId != null)
                    FutureBuilder<String>(
                      future: _getTeamName(ref, announcement.teamId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 14,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  snapshot.data!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String> _getTeamName(WidgetRef ref, String teamId) async {
    try {
      final teamService = TeamService();
      final doc = await teamService.getTeamById(teamId);
      return doc?.name ?? 'Team';
    } catch (e) {
      return 'Team';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final operations = ref.read(announcementOperationsProvider.notifier);

    if (action == 'pin') {
      final success = await operations.togglePin(announcement.id, user.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? (isPinned ? 'Announcement unpinned' : 'Announcement pinned')
                  : 'Failed to update announcement',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Announcement'),
          content: const Text('Are you sure you want to delete this announcement? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await operations.deleteAnnouncement(announcement.id, user.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success ? 'Announcement deleted' : 'Failed to delete announcement',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showAnnouncementDetails(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title with pin indicator
              Row(
                children: [
                  if (isPinned) ...[
                    Icon(Icons.push_pin, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      announcement.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Metadata
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, yyyy • h:mm a').format(announcement.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  if (announcement.teamId != null)
                    FutureBuilder<String>(
                      future: _getTeamName(ref, announcement.teamId!),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.group,
                                  size: 16,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  snapshot.data!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Full content
              Text(
                announcement.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
