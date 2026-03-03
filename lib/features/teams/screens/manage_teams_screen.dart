import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/club_service.dart';
import '../../../core/services/team_service.dart';
import '../../../models/club_model.dart';
import '../../../models/team_model.dart';
import '../../../models/team_membership_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';

/// Provider for team service
final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService();
});

/// Provider for teams by club
final teamsByClubProvider = StreamProvider.family<List<TeamModel>, String>((ref, clubId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamsByClub(clubId);
});

/// Provider for pending membership requests
final pendingMembershipsByClubProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, clubId) {
  final teamService = ref.watch(teamServiceProvider);
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

class ManageTeamsScreen extends ConsumerWidget {
  const ManageTeamsScreen({super.key});

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
                      _TeamsTab(clubId: clubId),
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

/// Tab showing all teams
class _TeamsTab extends ConsumerWidget {
  final String clubId;

  const _TeamsTab({required this.clubId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamsByClubProvider(clubId));
    final theme = Theme.of(context);

    return teamsAsync.when(
      data: (teams) {
        if (teams.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups_outlined, size: 80, color: theme.colorScheme.primary.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('No teams yet', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Create your first team to get started', style: theme.textTheme.bodyMedium),
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
                        Icon(Icons.people_outline, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text('${team.memberCount} members', style: theme.textTheme.bodySmall),
                        if (team.headId != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.star, size: 16, color: Colors.amber),
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
    final user = ref.watch(currentUserProvider);

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text('No pending requests', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('All membership requests have been reviewed', style: theme.textTheme.bodyMedium),
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
            final interviewStatus = membership.interviewStatus;
            final interviewResult = membership.interviewResult;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(request['userName'][0].toUpperCase()),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request['userName'],
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(request['userEmail'], style: theme.textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Text(
                                'Team: ${request['teamName']}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Interview Status Badge
                        _buildInterviewStatusBadge(theme, interviewStatus, interviewResult),
                      ],
                    ),
                    
                    // Show interview scheduled time if scheduled
                    if (interviewStatus == 'scheduled' && membership.interviewScheduledAt != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Interview: ${_formatDateTime(membership.interviewScheduledAt!.toDate())}',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Show interview notes if completed
                    if (interviewStatus == 'completed' && membership.interviewNotes != null && membership.interviewNotes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Interview Notes:',
                              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              membership.interviewNotes!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 16),
                    
                    // Action Buttons based on interview status
                    _buildActionButtons(
                      context,
                      ref,
                      theme,
                      membership,
                      user?.uid ?? '',
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

  Widget _buildInterviewStatusBadge(ThemeData theme, String interviewStatus, String? interviewResult) {
    Color badgeColor;
    IconData badgeIcon;
    String badgeText;

    if (interviewStatus == 'not_scheduled') {
      badgeColor = Colors.grey;
      badgeIcon = Icons.event_busy;
      badgeText = 'No Interview';
    } else if (interviewStatus == 'scheduled') {
      badgeColor = Colors.blue;
      badgeIcon = Icons.event;
      badgeText = 'Scheduled';
    } else if (interviewStatus == 'completed') {
      if (interviewResult == 'passed') {
        badgeColor = Colors.green;
        badgeIcon = Icons.check_circle;
        badgeText = 'Passed';
      } else {
        badgeColor = Colors.red;
        badgeIcon = Icons.cancel;
        badgeText = 'Failed';
      }
    } else {
      badgeColor = Colors.grey;
      badgeIcon = Icons.help_outline;
      badgeText = 'Unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              color: badgeColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    TeamMembershipModel membership,
    String adminId,
  ) {
    final interviewStatus = membership.interviewStatus;
    final interviewResult = membership.interviewResult;

    if (interviewStatus == 'not_scheduled') {
      // Show Schedule Interview and Reject buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectRequest(context, ref, membership.id),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _scheduleInterview(context, ref, membership),
              icon: const Icon(Icons.event),
              label: const Text('Schedule'),
            ),
          ),
        ],
      );
    } else if (interviewStatus == 'scheduled') {
      // Show Mark Complete and Reject buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectRequest(context, ref, membership.id),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _markInterviewCompleted(context, ref, membership),
              icon: const Icon(Icons.assignment_turned_in),
              label: const Text('Complete'),
            ),
          ),
        ],
      );
    } else if (interviewStatus == 'completed' && interviewResult == 'passed') {
      // Show Approve and Reject buttons
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _rejectRequest(context, ref, membership.id),
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _approveRequest(context, ref, membership.id, adminId),
              icon: const Icon(Icons.check),
              label: const Text('Approve'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          ),
        ],
      );
    } else if (interviewStatus == 'completed' && interviewResult == 'failed') {
      // Only show Reject button
      return FilledButton.icon(
        onPressed: () => _rejectRequest(context, ref, membership.id),
        icon: const Icon(Icons.close),
        label: const Text('Reject Application'),
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }

    // Default: show reject button
    return FilledButton.icon(
      onPressed: () => _rejectRequest(context, ref, membership.id),
      icon: const Icon(Icons.close),
      label: const Text('Reject'),
      style: FilledButton.styleFrom(
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  Future<void> _approveRequest(BuildContext context, WidgetRef ref, String membershipId, String reviewerId) async {
    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.approveMembershipRequest(
        membershipId: membershipId,
        reviewerId: reviewerId,
      );
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request approved successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectRequest(BuildContext context, WidgetRef ref, String membershipId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Request'),
        content: const Text('Are you sure you want to reject this membership request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamService = ref.read(teamServiceProvider);
        final user = ref.read(currentUserProvider);
        await teamService.rejectMembershipRequest(
          membershipId: membershipId,
          reviewerId: user?.uid ?? '',
        );
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request rejected'), backgroundColor: Colors.orange),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _scheduleInterview(BuildContext context, WidgetRef ref, TeamMembershipModel membership) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Interview'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select interview date and time:'),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(
                  '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final time = await showTimePicker(
                    context: dialogContext,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final interviewDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );

        final teamService = ref.read(teamServiceProvider);
        await teamService.scheduleInterview(
          membershipId: membership.id,
          interviewDateTime: interviewDateTime,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Interview scheduled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _markInterviewCompleted(BuildContext context, WidgetRef ref, TeamMembershipModel membership) async {
    String? selectedResult;
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Mark Interview Complete'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Interview Result:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Passed'),
                      value: 'passed',
                      groupValue: selectedResult,
                      onChanged: (value) => setState(() => selectedResult = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Failed'),
                      value: 'failed',
                      groupValue: selectedResult,
                      onChanged: (value) => setState(() => selectedResult = value),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any comments about the interview...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedResult == null
                  ? null
                  : () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedResult != null) {
      try {
        final teamService = ref.read(teamServiceProvider);
        await teamService.markInterviewCompleted(
          membershipId: membership.id,
          result: selectedResult!,
          notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Interview marked as ${selectedResult == 'passed' ? 'passed' : 'failed'}'),
              backgroundColor: selectedResult == 'passed' ? Colors.green : Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

/// Show dialog to create new team
void _showCreateTeamDialog(BuildContext context, WidgetRef ref, String clubId) {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Create New Team'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Team Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value?.isEmpty == true ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) => value?.isEmpty == true ? 'Please enter a description' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              try {
                final teamService = ref.read(teamServiceProvider);
                final user = ref.read(currentUserProvider);
                
                await teamService.createTeam(
                  clubId: clubId,
                  name: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  creatorId: user!.uid,
                );
                
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team created successfully'), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
