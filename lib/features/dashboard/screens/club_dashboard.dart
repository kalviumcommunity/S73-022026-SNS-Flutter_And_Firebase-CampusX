import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../auth/providers/auth_provider.dart';
import '../../events/providers/event_provider.dart';
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Column(
        children: [
          // Static Modern Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                  colorScheme.tertiary,
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top bar with Campus Connect and Logout
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Logo Icon
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Campus Connect Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Campus Connect',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    const Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4.0,
                                      color: Colors.black38,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                'Club Admin Dashboard',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Logout Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.logout_rounded),
                            color: Colors.white,
                            tooltip: 'Logout',
                            onPressed: () async {
                              await ref.read(authProvider.notifier).logout();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Decorative wave at bottom
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20.0),
              children: [
                  // Welcome Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.admin_panel_settings,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.name ?? 'Club Admin',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorScheme.primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  user?.role ?? 'N/A',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Quick Actions Grid
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _ModernActionCard(
                        icon: Icons.add_circle,
                        title: 'Create Event',
                        subtitle: 'Organize new events',
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        onTap: () => context.push('/create-event'),
                      ),
                      _ModernActionCard(
                        icon: Icons.calendar_month,
                        title: 'Calendar',
                        subtitle: 'View all events',
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                        onTap: () => context.push('/calendar'),
                      ),
                      _ModernActionCard(
                        icon: Icons.campaign,
                        title: 'Post',
                        subtitle: 'Announcements',
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.orange.shade600],
                        ),
                        onTap: () => context.push('/create-announcement'),
                      ),
                      _ModernActionCard(
                        icon: Icons.groups,
                        title: 'Teams',
                        subtitle: 'Manage teams',
                        gradient: LinearGradient(
                          colors: [Colors.teal.shade400, Colors.teal.shade600],
                        ),
                        onTap: () => context.push('/manage-teams'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // More Options
                  Text(
                    'More Options',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        children: [
                          _OptionTile(
                            icon: Icons.event_note,
                            title: 'Manage Events',
                            subtitle: 'Edit and track your events',
                            iconColor: Colors.indigo,
                            onTap: () => context.push('/events'),
                          ),
                          const Divider(height: 1),
                          _ViewAnnouncementsButton(),
                          const Divider(height: 1),
                          _OptionTile(
                            icon: Icons.person,
                            title: 'My Profile',
                            subtitle: 'View and edit your profile',
                            iconColor: Colors.blue,
                            onTap: () => context.push('/profile'),
                          ),
                          const Divider(height: 1),
                          _OptionTile(
                            icon: Icons.settings,
                            title: 'Settings',
                            subtitle: 'Manage account settings',
                            iconColor: Colors.grey,
                            onTap: () => context.push('/settings'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // My Events & Registrations Section
                  Text(
                    'My Events & Registrations',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
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
          ],
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
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');
    final isUpcoming = event.date.isAfter(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isUpcoming ? 0.08 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            context.push('/event-detail/${event.id}');
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUpcoming
                    ? [
                        colorScheme.surfaceContainerHighest,
                        colorScheme.surface,
                      ]
                    : [
                        colorScheme.surfaceContainerLow,
                        colorScheme.surfaceContainerLowest,
                      ],
              ),
              border: Border.all(
                color: isUpcoming
                    ? colorScheme.primary.withValues(alpha: 0.1)
                    : colorScheme.outline.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Decorative corner circle
                Positioned(
                  right: -20,
                  top: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUpcoming
                          ? colorScheme.primary.withValues(alpha: 0.05)
                          : colorScheme.onSurface.withValues(alpha: 0.02),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row with status badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isUpcoming
                                    ? colorScheme.onSurface
                                    : colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Status badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isUpcoming
                                    ? [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ]
                                    : [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isUpcoming ? Colors.green : Colors.grey)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isUpcoming ? Icons.check_circle : Icons.history,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isUpcoming ? 'Upcoming' : 'Past',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Date and Location info containers
                      Row(
                        children: [
                          // Date container
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUpcoming
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: isUpcoming
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateFormat.format(event.date),
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isUpcoming
                                                ? colorScheme.onPrimaryContainer
                                                : colorScheme.onSurface,
                                          ),
                                        ),
                                        Text(
                                          timeFormat.format(event.date),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: isUpcoming
                                                ? colorScheme.onPrimaryContainer
                                                    .withValues(alpha: 0.8)
                                                : colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Location container
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUpcoming
                                    ? colorScheme.secondaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: isUpcoming
                                        ? colorScheme.onSecondaryContainer
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isUpcoming
                                            ? colorScheme.onSecondaryContainer
                                            : colorScheme.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Capacity info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isUpcoming
                              ? colorScheme.tertiaryContainer
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: isUpcoming
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Capacity: ${event.capacity}',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isUpcoming
                                    ? colorScheme.onTertiaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
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
              ],
            ),
          ),
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

        return _OptionTile(
          icon: Icons.announcement,
          title: 'View Announcements',
          subtitle: 'See all club announcements',
          iconColor: Colors.amber,
          onTap: () => context.push('/announcements/$clubId'),
        );
      },
      loading: () => _OptionTile(
        icon: Icons.announcement,
        title: 'View Announcements',
        subtitle: 'Loading...',
        iconColor: Colors.amber,
        enabled: false,
        onTap: () {},
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Modern action card widget with gradient background
class _ModernActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  const _ModernActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern option tile widget with colored icon container
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;
  final bool enabled;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      enabled: enabled,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
    );
  }
}
