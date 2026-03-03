import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../events/providers/event_provider.dart';
import '../../clubs/providers/club_provider.dart';
import '../../../models/event_model.dart';
import '../../../models/club_model.dart';
import '../../../core/services/club_service.dart';

/// Provider for clubs where user is admin
final userAdminClubsProvider = StreamProvider<List<ClubModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  final clubService = ClubService();
  
  if (user == null) {
    return Stream.value([]);
  }
  
  return clubService.getClubsByAdmin(user.uid);
});

class ClubDashboard extends ConsumerWidget {
  const ClubDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Admin Dashboard'),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome, ${user?.name ?? 'Club Admin'}!',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Role: ${user?.role ?? 'N/A'}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Quick Actions Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.add_circle),
                        title: const Text('Create Event'),
                        subtitle: const Text('Organize new club events'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          context.push('/create-event');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.event_note),
                        title: const Text('Manage Events'),
                        subtitle: const Text('Edit and track your events'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          context.push('/events');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.campaign),
                        title: const Text('Post Announcement'),
                        subtitle: const Text('Notify club members'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          context.push('/create-announcement');
                        },
                      ),
                      const Divider(),
                      _ViewAnnouncementsButton(),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.groups),
                        title: const Text('Manage Teams'),
                        subtitle: const Text('Manage teams, members & requests'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () {
                          context.push('/manage-teams');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // My Events & Registrations Section
              Text(
                'My Events & Registrations',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (user != null)
                _MyEventsSection(userId: user.uid)
              else
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text('Please log in to view your events'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to display club admin's events with registration management
class _MyEventsSection extends ConsumerWidget {
  final String userId;

  const _MyEventsSection({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsByCreatorProvider(userId));
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
                    'No events created yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first event to get started',
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
              ...pastEvents.map((event) => _EventCard(event: event)),
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

/// Widget for individual event card
class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isUpcoming = event.date.isAfter(DateTime.now());

    return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Event title and status
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isUpcoming
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isUpcoming ? 'Upcoming' : 'Past',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isUpcoming
                                  ? theme.colorScheme.onPrimaryContainer
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Event details
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${dateFormat.format(event.date)} at ${timeFormat.format(event.date)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 6),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: theme.colorScheme.tertiary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Capacity: ${event.capacity}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/event-detail/${event.id}');
                            },
                            icon: const Icon(Icons.visibility, size: 18),
                            label: const Text('View Details'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              context.push('/event-registrations/${event.id}');
                            },
                            icon: const Icon(Icons.how_to_reg, size: 18),
                            label: const Text('Registrations'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
  }
}

/// Widget to display "View Announcements" button with club selection
class _ViewAnnouncementsButton extends ConsumerWidget {
  const _ViewAnnouncementsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider).user?.uid;
    
    if (userId == null) {
      return const SizedBox.shrink();
    }

    final clubsAsync = ref.watch(userAdminClubsProvider);

    return clubsAsync.when(
      data: (adminClubs) {
        if (adminClubs.isEmpty) {
          return const SizedBox.shrink();
        }

        // Use first admin club for announcements
        final clubId = adminClubs.first.id;

        return ListTile(
          leading: const Icon(Icons.announcement),
          title: const Text('View Announcements'),
          subtitle: const Text('See all club announcements'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            context.push('/announcements/$clubId');
          },
        );
      },
      loading: () => ListTile(
        leading: const Icon(Icons.announcement),
        title: const Text('View Announcements'),
        subtitle: const Text('Loading...'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        enabled: false,
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
