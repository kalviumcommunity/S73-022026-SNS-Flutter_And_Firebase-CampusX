import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/services/team_service.dart';
import '../../../core/models/filter_models.dart';
import '../../../models/announcement_model.dart';
import '../../../models/team_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/announcement_filter_provider.dart';

/// Provider for teams by club (for filter dropdown)
final teamsByClubFilterProvider = StreamProvider.family<List<TeamModel>, String>((ref, clubId) {
  final teamService = TeamService();
  return teamService.getTeamsByClub(clubId);
});

class EnhancedAnnouncementsListScreen extends ConsumerStatefulWidget {
  final String clubId;

  const EnhancedAnnouncementsListScreen({
    super.key,
    required this.clubId,
  });

  @override
  ConsumerState<EnhancedAnnouncementsListScreen> createState() => _EnhancedAnnouncementsListScreenState();
}

class _EnhancedAnnouncementsListScreenState extends ConsumerState<EnhancedAnnouncementsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(announcementFiltersProvider(widget.clubId));
    _searchController.text = currentFilters.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(announcementFiltersProvider(widget.clubId).notifier).setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final announcementsAsync = ref.watch(filteredAnnouncementsProvider(widget.clubId));
    final filters = ref.watch(announcementFiltersProvider(widget.clubId));
    final currentUser = ref.watch(currentUserProvider);
    final isClubAdmin = currentUser?.role == 'club_admin';
    final teamsAsync = ref.watch(teamsByClubFilterProvider(widget.clubId));

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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search announcements...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: _onSearchChanged,
            ),
          ),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Date Filter Chips
                ChoiceChip(
                  label: const Text('All'),
                  selected: filters.dateFilter == AnnouncementDateFilter.all,
                  onSelected: (_) {
                    ref.read(announcementFiltersProvider(widget.clubId).notifier)
                        .setDateFilter(AnnouncementDateFilter.all);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Today'),
                  selected: filters.dateFilter == AnnouncementDateFilter.today,
                  onSelected: (_) {
                    ref.read(announcementFiltersProvider(widget.clubId).notifier)
                        .setDateFilter(AnnouncementDateFilter.today);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('This Week'),
                  selected: filters.dateFilter == AnnouncementDateFilter.thisWeek,
                  onSelected: (_) {
                    ref.read(announcementFiltersProvider(widget.clubId).notifier)
                        .setDateFilter(AnnouncementDateFilter.thisWeek);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('This Month'),
                  selected: filters.dateFilter == AnnouncementDateFilter.thisMonth,
                  onSelected: (_) {
                    ref.read(announcementFiltersProvider(widget.clubId).notifier)
                        .setDateFilter(AnnouncementDateFilter.thisMonth);
                  },
                ),
                const SizedBox(width: 8),
                // Team Filter (if multiple teams)
                teamsAsync.when(
                  data: (teams) {
                    if (teams.length <= 1) return const SizedBox.shrink();
                    return PopupMenuButton<String>(
                      child: Chip(
                        label: Text(filters.teamId == null ? 'All Teams' : 'Selected Team'),
                        avatar: const Icon(Icons.filter_list, size: 18),
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('All Teams'),
                        ),
                        ...teams.map((team) => PopupMenuItem(
                              value: team.id,
                              child: Text(team.name),
                            )),
                      ],
                      onSelected: (teamId) {
                        ref.read(announcementFiltersProvider(widget.clubId).notifier)
                            .setTeamFilter(teamId);
                      },
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                if (filters.hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.clear_all, size: 18),
                    label: const Text('Clear'),
                    onPressed: () {
                      ref.read(announcementFiltersProvider(widget.clubId).notifier).reset();
                      _searchController.clear();
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Announcements List
          Expanded(
            child: announcementsAsync.when(
              data: (announcements) {
                if (announcements.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          filters.hasActiveFilters ? Icons.search_off : Icons.campaign_outlined,
                          size: 80,
                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          filters.hasActiveFilters ? 'No announcements found' : 'No announcements yet',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          filters.hasActiveFilters
                              ? 'Try adjusting your filters'
                              : isClubAdmin
                                  ? 'Tap + to create your first announcement'
                                  : 'Check back later for updates',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                            clubId: widget.clubId,
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
                            Icon(Icons.announcement_outlined,
                                size: 20, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
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
                            clubId: widget.clubId,
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
          ),
        ],
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
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd, yyyy').format(announcement.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (announcement.teamId != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.groups, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text('Team', style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAnnouncementDetails(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('MMM dd, yyyy • hh:mm a').format(announcement.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Divider(height: 24),
              Text(
                announcement.content,
                style: theme.textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    final announcementService = ref.read(announcementServiceProvider);

    if (action == 'pin') {
      await announcementService.togglePin(clubId, announcement.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isPinned ? 'Announcement unpinned' : 'Announcement pinned')),
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
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await announcementService.deleteAnnouncement(clubId, announcement.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Announcement deleted')),
          );
        }
      }
    }
  }
}
