import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../../events/providers/registration_provider.dart';
import '../providers/role_request_provider.dart';
import '../../../models/event_model.dart';

class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);
    final roleRequestState = ref.watch(roleRequestOperationsProvider);
    final membershipAsync = ref.watch(userTeamMembershipProvider);
    final userClubAsync = ref.watch(userClubProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon
              Icon(
                Icons.school,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${user?.name ?? 'Student'}!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Student Dashboard',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Role: ${user?.role ?? 'N/A'}',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.event),
                        title: const Text('Browse Events'),
                        subtitle: const Text('Find and register for events'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.push('/events');
                        },
                      ),
                      const Divider(),
                      // Show club section based on membership status
                      membershipAsync.when(
                        data: (membership) {
                          if (membership != null) {
                            // User has approved membership - show My Club
                            return userClubAsync.when(
                              data: (club) {
                                if (club == null) {
                                  return const SizedBox.shrink();
                                }
                                return Column(
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.star),
                                      title: const Text('My Club'),
                                      subtitle: Text(club.name),
                                      trailing:
                                          const Icon(Icons.arrow_forward_ios),
                                      onTap: () {
                                        context.push('/clubs/${club.id}');
                                      },
                                    ),
                                    const Divider(),
                                  ],
                                );
                              },
                              loading: () => const ListTile(
                                leading: Icon(Icons.star),
                                title: Text('My Club'),
                                subtitle: Text('Loading...'),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          } else {
                            // User doesn't have membership - show Discover Clubs
                            return Column(
                              children: [
                                ListTile(
                                  leading: const Icon(Icons.explore),
                                  title: const Text('Discover Clubs'),
                                  subtitle: const Text(
                                      'Find and join clubs on campus'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    context.push('/clubs');
                                  },
                                ),
                                const Divider(),
                              ],
                            );
                          }
                        },
                        loading: () => const Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.groups),
                              title: Text('Clubs'),
                              subtitle: Text('Loading...'),
                            ),
                            Divider(),
                          ],
                        ),
                        error: (_, __) => const Column(
                          children: [
                            ListTile(
                              leading: Icon(Icons.groups),
                              title: Text('Clubs'),
                              subtitle: Text('Error loading club information'),
                            ),
                            Divider(),
                          ],
                        ),
                      ),
                      // Announcements - show if user has club membership
                      membershipAsync.when(
                        data: (membership) {
                          if (membership != null) {
                            // User has membership - show announcements
                            return userClubAsync.when(
                              data: (club) {
                                if (club == null) {
                                  return const SizedBox.shrink();
                                }
                                return ListTile(
                                  leading: const Icon(Icons.notifications),
                                  title: const Text('Announcements'),
                                  subtitle: const Text('View latest announcements'),
                                  trailing: const Icon(Icons.arrow_forward_ios),
                                  onTap: () {
                                    context.push('/announcements/${club.id}');
                                  },
                                );
                              },
                              loading: () => const ListTile(
                                leading: Icon(Icons.notifications),
                                title: Text('Announcements'),
                                subtitle: Text('Loading...'),
                                enabled: false,
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          } else {
                            // User doesn't have membership - show disabled announcements
                            return ListTile(
                              leading: Icon(Icons.notifications, 
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                              title: Text('Announcements',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                              subtitle: const Text('Join a club to view announcements'),
                              enabled: false,
                            );
                          }
                        },
                        loading: () => const ListTile(
                          leading: Icon(Icons.notifications),
                          title: Text('Announcements'),
                          subtitle: Text('Loading...'),
                          enabled: false,
                        ),
                        error: (_, __) => ListTile(
                          leading: Icon(Icons.notifications,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                          title: Text('Announcements',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          subtitle: const Text('Unable to load announcements'),
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // My Team Section
              if (user != null) ...[
                Text(
                  'My Team',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _MyTeamSection(),
                const SizedBox(height: 24),
              ],
              
              // My Events Section
              if (user != null) ...[
                Text(
                  'My Events',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _MyEventsSection(userId: user.uid),
                const SizedBox(height: 24),
              ],
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: roleRequestState.isLoading
                      ? null
                      : () => _requestClubAdminAccess(context, ref, user?.uid),
                  icon: roleRequestState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.admin_panel_settings),
                  label: Text(
                    roleRequestState.isLoading
                        ? 'Submitting Request...'
                        : 'Request Club Admin Access',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle club admin access request
  void _requestClubAdminAccess(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await ref
        .read(roleRequestOperationsProvider.notifier)
        .requestRoleUpgrade(userId);

    if (context.mounted) {
      final state = ref.read(roleRequestOperationsProvider);
      
      if (success && state.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.successMessage!),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (!success && state.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Clear messages after showing
      ref.read(roleRequestOperationsProvider.notifier).clearMessages();
    }
  }
}

/// Widget to display student's registered events
class _MyEventsSection extends ConsumerWidget {
  final String userId;

  const _MyEventsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(userRegisteredEventsProvider(userId));
    final theme = Theme.of(context);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 48,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events registered',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Browse events to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Separate and sort events by upcoming/past
        final now = DateTime.now();
        final upcomingEvents = events.where((e) => e.date.isAfter(now)).toList();
        final pastEvents = events.where((e) => !e.date.isAfter(now)).toList();

        // Sort upcoming events by date (ascending - soonest first)
        upcomingEvents.sort((a, b) => a.date.compareTo(b.date));
        // Sort past events by date (descending - most recent first)
        pastEvents.sort((a, b) => b.date.compareTo(a.date));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upcoming Events Section
            if (upcomingEvents.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.upcoming,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upcoming Events (${upcomingEvents.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ...upcomingEvents.map((event) => _EventCard(event: event)),
              const SizedBox(height: 16),
            ],

            // Past Events Section
            if (pastEvents.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      size: 20,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Past Events (${pastEvents.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              ...pastEvents.map((event) => _EventCard(event: event, isPast: true)),
            ],
          ],
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading events',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display individual event card
class _EventCard extends StatelessWidget {
  final EventModel event;
  final bool isPast;

  const _EventCard({
    required this.event,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr = DateFormat('MMM d, yyyy').format(event.date);
    final timeStr = DateFormat('h:mm a').format(event.date);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isPast ? 1 : 2,
      child: InkWell(
        onTap: () {
          context.push('/event-detail/${event.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.event,
                    color: isPast
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                        : theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPast
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                event.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: isPast ? 0.5 : 0.8),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeStr,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display student's team membership
class _MyTeamSection extends ConsumerWidget {
  const _MyTeamSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipAsync = ref.watch(userTeamMembershipProvider);
    final teamAsync = ref.watch(userTeamProvider);
    final theme = Theme.of(context);

    return membershipAsync.when(
      data: (membership) {
        if (membership == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 48,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Not part of any team',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Join a club to become a team member',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // User has membership, show team details
        return teamAsync.when(
          data: (team) {
            if (team == null) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Team information not available',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              );
            }

            // Determine if user is team head
            final isHead = membership.role == 'head' || team.headId == membership.userId;
            
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.groups,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isHead
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isHead ? 'Team Head' : 'Team Member',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isHead
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      team.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: theme.colorScheme.outlineVariant),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoItem(
                          context,
                          Icons.people,
                          'Members',
                          team.memberCount.toString(),
                        ),
                        _buildInfoItem(
                          context,
                          Icons.check_circle,
                          'Status',
                          membership.status,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (error, stack) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error loading team: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading membership',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
