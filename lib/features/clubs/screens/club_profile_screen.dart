import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/team_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/club_provider.dart';

class ClubProfileScreen extends ConsumerWidget {
  final String clubId;

  const ClubProfileScreen({
    super.key,
    required this.clubId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clubService = ref.watch(clubServiceProvider);
    final teamsAsync = ref.watch(teamsByClubProvider(clubId));
    final membershipAsync = ref.watch(userMembershipWithStatusProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Club Profile',
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
      body: FutureBuilder(
        future: clubService.getClubById(clubId),
        builder: (context, clubSnapshot) {
          if (clubSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (clubSnapshot.hasError || !clubSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading club',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            );
          }

          final club = clubSnapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Club Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.groups,
                          size: 50,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        club.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 20,
                            color: Colors.white.withOpacity(0.9),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${club.memberCount} members',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Club Description
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        club.description,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),

                const Divider(),

                // Teams Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teams',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        currentUser?.role == 'college_admin'
                            ? 'View all teams in this club'
                            : 'Join a team to become a member of this club',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Teams List
                teamsAsync.when(
                  data: (teams) {
                    if (teams.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            'No teams available yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: teams.length,
                      itemBuilder: (context, index) {
                        final team = teams[index] as TeamModel;
                        
                        return membershipAsync.when(
                          data: (membership) {
                            // Check if user already has a membership
                            final hasMembership = membership != null;
                            final isInThisTeam = membership?.teamId == team.id;
                            final isCollegeAdmin = currentUser?.role == 'college_admin';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                team.name,
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                team.description,
                                                style: theme.textTheme.bodyMedium,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${team.memberCount} members',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurface
                                                      .withOpacity(0.6),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    // Don't show join buttons for college admins
                                    if (!isCollegeAdmin) ...[
                                      const SizedBox(height: 12),
                                      if (isInThisTeam) ...[
                                        if (membership?.status == 'approved')
                                          ElevatedButton.icon(
                                            onPressed: null,
                                            icon: const Icon(Icons.check_circle),
                                            label: const Text('Member'),
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(double.infinity, 40),
                                              backgroundColor: Colors.green.shade100,
                                              foregroundColor: Colors.green.shade900,
                                            ),
                                          )
                                        else if (membership?.status == 'pending') ...[
                                          // Show detailed application status
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: theme.colorScheme.primary.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.pending_actions,
                                                      size: 20,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Application Status',
                                                      style: theme.textTheme.titleSmall?.copyWith(
                                                        fontWeight: FontWeight.bold,
                                                        color: theme.colorScheme.primary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                _buildInterviewStatusRow(
                                                  theme,
                                                  membership!.interviewStatus,
                                                  membership.interviewResult,
                                                ),
                                                if (membership.interviewStatus == 'scheduled' &&
                                                    membership.interviewScheduledAt != null) ...[
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.calendar_today,
                                                          size: 16,
                                                          color: Colors.blue.shade700,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            'Interview: ${_formatInterviewDateTime(membership.interviewScheduledAt!.toDate())}',
                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                              color: Colors.blue.shade900,
                                                              fontWeight: FontWeight.w500,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                if (membership.interviewStatus == 'completed' &&
                                                    membership.interviewResult == 'passed') ...[
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.check_circle,
                                                          size: 16,
                                                          color: Colors.green.shade700,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            'Interview passed! Waiting for final approval.',
                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                              color: Colors.green.shade900,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                                if (membership.interviewStatus == 'completed' &&
                                                    membership.interviewResult == 'failed') ...[
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.shade50,
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.cancel,
                                                          size: 16,
                                                          color: Colors.red.shade700,
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            'Interview not successful. Application will be reviewed.',
                                                            style: theme.textTheme.bodySmall?.copyWith(
                                                              color: Colors.red.shade900,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ] else if (hasMembership)
                                        ElevatedButton.icon(
                                          onPressed: null,
                                          icon: const Icon(Icons.info_outline),
                                          label: const Text(
                                            'Already in another team',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(double.infinity, 40),
                                          ),
                                        )
                                      else
                                        ElevatedButton.icon(
                                          onPressed: () => _requestTeamMembership(
                                            context,
                                            ref,
                                            team.id,
                                            currentUser?.uid,
                                          ),
                                          icon: const Icon(Icons.add),
                                          label: const Text('Request to Join'),
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(double.infinity, 40),
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                          loading: () => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    team.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    team.description,
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 12),
                                  const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          error: (_, __) => Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(team.name),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Error loading teams: $error',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  void _requestTeamMembership(
    BuildContext context,
    WidgetRef ref,
    String teamId,
    String? userId,
  ) async {
    if (userId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to join a team'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.requestTeamMembership(
        teamId: teamId,
        userId: userId,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team membership request submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Refresh membership status
        ref.invalidate(userMembershipWithStatusProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildInterviewStatusRow(ThemeData theme, String interviewStatus, String? interviewResult) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (interviewStatus == 'not_scheduled') {
      statusColor = Colors.grey;
      statusIcon = Icons.event_busy;
      statusText = 'Interview not yet scheduled';
    } else if (interviewStatus == 'scheduled') {
      statusColor = Colors.blue;
      statusIcon = Icons.event;
      statusText = 'Interview scheduled';
    } else if (interviewStatus == 'completed') {
      if (interviewResult == 'passed') {
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Interview passed';
      } else {
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Interview not passed';
      }
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.help_outline;
      statusText = 'Unknown status';
    }

    return Row(
      children: [
        Icon(statusIcon, size: 18, color: statusColor),
        const SizedBox(width: 8),
        Text(
          statusText,
          style: TextStyle(
            fontSize: 14,
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatInterviewDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);
    
    final month = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ][dateTime.month - 1];
    
    final time = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    
    if (difference.inDays == 0) {
      return 'Today at $time';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at $time';
    } else if (difference.inDays > 0 && difference.inDays < 7) {
      final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dateTime.weekday - 1];
      return '$weekday at $time';
    } else {
      return '$month ${dateTime.day} at $time';
    }
  }
}
