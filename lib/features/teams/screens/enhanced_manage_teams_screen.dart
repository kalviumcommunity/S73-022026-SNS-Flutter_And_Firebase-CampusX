import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/team_service.dart';
import '../../../models/club_model.dart';
import '../../../models/team_model.dart';
import '../../../models/team_membership_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../providers/team_filter_provider.dart';

/// Local team service provider to avoid conflicts
final teamServiceLocalProvider = Provider<TeamService>((ref) {
  return TeamService();
});

/// Provider for pending membership requests
final pendingMembershipsByClubProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, clubId) {
  final teamService = ref.watch(teamServiceLocalProvider);
  return teamService.getPendingMembershipsByClub(clubId);
});

/// Provider for clubs where user is admin (fetched from database)
final userAdminClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final clubService = ref.watch(clubServiceProvider);
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return clubService.getClubsByAdmin(user.uid);
});

class EnhancedManageTeamsScreen extends ConsumerWidget {
  const EnhancedManageTeamsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final adminClubsAsync = ref.watch(userAdminClubsProvider);
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Teams')),
        body: const Center(child: Text('Please log in')),
      );
    }

    return adminClubsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Manage Teams')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: const Text('Manage Teams')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Error: $error'),
            ],
          ),
        ),
      ),
      data: (clubs) {
        if (clubs.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Manage Teams')),
            body: Center(
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
            ),
          );
        }

        // For simplicity, show teams for the first club
        // TODO: Add club selector if user admin of multiple clubs
        final clubId = clubs.first.id;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Teams'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  _showCreateTeamDialog(context, ref, clubId);
                },
              ),
            ],
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Teams', icon: Icon(Icons.groups)),
                    Tab(text: 'Pending Requests', icon: Icon(Icons.pending_actions)),
                  ],
                  labelColor: theme.colorScheme.primary,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _EnhancedTeamsTab(clubId: clubId),
                      _PendingRequestsTab(clubId: clubId),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Enhanced Teams tab with search functionality
class _EnhancedTeamsTab extends ConsumerStatefulWidget {
  final String clubId;

  const _EnhancedTeamsTab({required this.clubId});

  @override
  ConsumerState<_EnhancedTeamsTab> createState() => _EnhancedTeamsTabState();
}

class _EnhancedTeamsTabState extends ConsumerState<_EnhancedTeamsTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final currentFilters = ref.read(teamFiltersProvider(widget.clubId));
    _searchController.text = currentFilters.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(teamFiltersProvider(widget.clubId).notifier).setSearchQuery(query);
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(filteredTeamsProvider(widget.clubId));
    final filters = ref.watch(teamFiltersProvider(widget.clubId));
    final theme = Theme.of(context);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search teams...',
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

        // Teams List
        Expanded(
          child: teamsAsync.when(
            data: (teams) {
              if (teams.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        filters.hasActiveFilters ? Icons.search_off : Icons.groups_outlined,
                        size: 80,
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        filters.hasActiveFilters ? 'No teams found' : 'No teams yet',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        filters.hasActiveFilters
                            ? 'Try a different search query'
                            : 'Create your first team to get started',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: teams.length,
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(Icons.people, color: theme.colorScheme.primary),
                      ),
                      title: Text(
                        team.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(team.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                              const SizedBox(width: 4),
                              Text('${team.memberCount} members', style: theme.textTheme.bodySmall),
                              if (team.headId != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.star, size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text('Has Head', style: theme.textTheme.bodySmall),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        context.push('/teams/${team.id}');
                      },
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Error loading teams', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(error.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tab showing pending membership requests
class _PendingRequestsTab extends ConsumerWidget {
  final String clubId;

  const _PendingRequestsTab({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(pendingMembershipsByClubProvider(clubId));
    final theme = Theme.of(context);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No pending requests', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('All caught up!', style: theme.textTheme.bodyMedium),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final membership = request['membership'] as TeamMembershipModel;
            final teamName = request['teamName'] as String;
            final userName = request['userName'] as String;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(16),
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(Icons.person_add, color: theme.colorScheme.secondary),
                ),
                title: Text(userName, style: theme.textTheme.titleMedium),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('Team: $teamName'),
                    const SizedBox(height: 4),
                    Text('Role: ${membership.role}', style: theme.textTheme.bodySmall),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () async {
                        await ref
                            .read(teamServiceLocalProvider)
                            .approveMembershipRequest(
                              membershipId: membership.id,
                              reviewerId: ref.read(currentUserProvider)!.uid,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request approved')),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () async {
                        await ref
                            .read(teamServiceLocalProvider)
                            .rejectMembershipRequest(
                              membershipId: membership.id,
                              reviewerId: ref.read(currentUserProvider)!.uid,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request rejected')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Error loading requests', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(error.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Show create team dialog
void _showCreateTeamDialog(BuildContext context, WidgetRef ref, String clubId) {
  final nameController = TextEditingController();
  final descController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Create Team'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Team Name'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (nameController.text.isNotEmpty && descController.text.isNotEmpty) {
              final user = ref.read(currentUserProvider);
              if (user != null) {
                await ref.read(teamServiceLocalProvider).createTeam(
                  clubId: clubId,
                  name: nameController.text.trim(),
                  description: descController.text.trim(),
                  creatorId: user.uid,
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team created successfully')),
                  );
                }
              }
            }
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}
