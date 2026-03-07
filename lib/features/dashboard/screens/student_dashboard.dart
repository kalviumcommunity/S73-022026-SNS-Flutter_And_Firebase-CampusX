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
      body: Column(
        children: [
          // Static Modern Header
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
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
                            Icons.hub_rounded,
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
                                'Student Dashboard',
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
                  // Welcome Card with Gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.school_rounded,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome Back!',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user?.name ?? 'Student',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  user?.role.toUpperCase() ?? 'STUDENT',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
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
                  const SizedBox(height: 24),

                  // Quick Actions Grid
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _ModernActionCard(
                        icon: Icons.event_rounded,
                        title: 'Browse Events',
                        subtitle: 'Find events',
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade600],
                        ),
                        onTap: () => context.push('/events'),
                      ),
                      _ModernActionCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Calendar',
                        subtitle: 'View schedule',
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade400, Colors.purple.shade600],
                        ),
                        onTap: () => context.push('/calendar'),
                      ),
                      _ModernActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan QR',
                        subtitle: 'Mark attendance',
                        gradient: LinearGradient(
                          colors: [Colors.green.shade400, Colors.green.shade600],
                        ),
                        onTap: () => context.push('/scan-attendance'),
                      ),
                      _ModernActionCard(
                        icon: Icons.history_rounded,
                        title: 'Attendance',
                        subtitle: 'View history',
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.orange.shade600],
                        ),
                        onTap: () => context.push('/my-attendance'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // More Options
                  Text(
                    'More Options',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                        children: [
                        // Club/Discoveries section with membership logic
                        membershipAsync.when(
                          data: (membership) {
                            if (membership != null) {
                              return userClubAsync.when(
                                data: (club) {
                                  if (club == null) return const SizedBox.shrink();
                                  return _OptionTile(
                                    icon: Icons.star_rounded,
                                    title: 'My Club',
                                    subtitle: club.name,
                                    iconColor: Colors.amber,
                                    onTap: () => context.push('/clubs/${club.id}'),
                                  );
                                },
                                loading: () => _OptionTile(
                                  icon: Icons.star_rounded,
                                  title: 'My Club',
                                  subtitle: 'Loading...',
                                  iconColor: Colors.amber,
                                  onTap: () {},
                                ),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            } else {
                              return _OptionTile(
                                icon: Icons.explore_rounded,
                                title: 'Discover Clubs',
                                subtitle: 'Find and join clubs',
                                iconColor: Colors.teal,
                                onTap: () => context.push('/clubs'),
                              );
                            }
                          },
                          loading: () => _OptionTile(
                            icon: Icons.groups_rounded,
                            title: 'Clubs',
                            subtitle: 'Loading...',
                            iconColor: Colors.grey,
                            onTap: () {},
                          ),
                          error: (_, __) => _OptionTile(
                            icon: Icons.groups_rounded,
                            title: 'Clubs',
                            subtitle: 'Error loading',
                            iconColor: Colors.grey,
                            onTap: () {},
                          ),
                        ),
                        const Divider(height: 1),
                        
                        // Announcements
                        membershipAsync.when(
                          data: (membership) {
                            if (membership != null) {
                              return userClubAsync.when(
                                data: (club) {
                                  if (club == null) return const SizedBox.shrink();
                                  return _OptionTile(
                                    icon: Icons.notifications_active_rounded,
                                    title: 'Announcements',
                                    subtitle: 'View latest updates',
                                    iconColor: Colors.red,
                                    onTap: () => context.push('/announcements/${club.id}'),
                                  );
                                },
                                loading: () => _OptionTile(
                                  icon: Icons.notifications_rounded,
                                  title: 'Announcements',
                                  subtitle: 'Loading...',
                                  iconColor: Colors.grey,
                                  onTap: () {},
                                ),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            } else {
                              return _OptionTile(
                                icon: Icons.notifications_off_rounded,
                                title: 'Announcements',
                                subtitle: 'Join a club first',
                                iconColor: Colors.grey,
                                enabled: false,
                                onTap: () {},
                              );
                            }
                          },
                          loading: () => _OptionTile(
                            icon: Icons.notifications_rounded,
                            title: 'Announcements',
                            subtitle: 'Loading...',
                            iconColor: Colors.grey,
                            onTap: () {},
                          ),
                          error: (_, __) => _OptionTile(
                            icon: Icons.notifications_off_rounded,
                            title: 'Announcements',
                            subtitle: 'Unable to load',
                            iconColor: Colors.grey,
                            enabled: false,
                            onTap: () {},
                          ),
                        ),
                        const Divider(height: 1),
                        
                        _OptionTile(
                          icon: Icons.person_rounded,
                          title: 'My Profile',
                          subtitle: 'View and edit profile',
                          iconColor: Colors.blue,
                          onTap: () => context.push('/profile'),
                        ),
                        const Divider(height: 1),
                        _OptionTile(
                          icon: Icons.settings_rounded,
                          title: 'Settings',
                          subtitle: 'Manage account',
                          iconColor: Colors.grey.shade700,
                          onTap: () => context.push('/settings'),
                        ),
                      ],
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
                  
                  // Request Club Admin Access Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.tertiary,
                          theme.colorScheme.primary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: roleRequestState.isLoading
                            ? null
                            : () => _requestClubAdminAccess(context, ref, user?.uid),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 20,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (roleRequestState.isLoading)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              const SizedBox(width: 12),
                              Text(
                                roleRequestState.isLoading
                                    ? 'Submitting Request...'
                                    : 'Request Club Admin Access',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
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
            // Upcoming Events Section (Collapsible)
            if (upcomingEvents.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: true,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.upcoming,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      'Upcoming Events',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    subtitle: Text(
                      '${upcomingEvents.length} event${upcomingEvents.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    children: upcomingEvents.map((event) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _EventCard(event: event),
                    )).toList(),
                  ),
                ),
              ),
            ],

            // Past Events Section (Collapsible)
            if (pastEvents.isNotEmpty) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    childrenPadding: const EdgeInsets.only(bottom: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    title: Text(
                      'Past Events',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    subtitle: Text(
                      '${pastEvents.length} event${pastEvents.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    children: pastEvents.map((event) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: _EventCard(event: event, isPast: true),
                    )).toList(),
                  ),
                ),
              ),
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
    final colorScheme = theme.colorScheme;
    final dateStr = DateFormat('MMM d, yyyy').format(event.date);
    final timeStr = DateFormat('h:mm a').format(event.date);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isPast ? 0.05 : 0.08),
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
                colors: isPast
                    ? [
                        colorScheme.surfaceContainerLow,
                        colorScheme.surfaceContainerLowest,
                      ]
                    : [
                        colorScheme.surfaceContainerHighest,
                        colorScheme.surface,
                      ],
              ),
              border: Border.all(
                color: isPast
                    ? colorScheme.outline.withValues(alpha: 0.1)
                    : colorScheme.primary.withValues(alpha: 0.1),
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
                      color: isPast
                          ? colorScheme.onSurface.withValues(alpha: 0.02)
                          : colorScheme.primary.withValues(alpha: 0.05),
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
                                color: isPast
                                    ? colorScheme.onSurface.withValues(alpha: 0.6)
                                    : colorScheme.onSurface,
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
                                colors: isPast
                                    ? [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ]
                                    : [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPast ? Colors.grey : Colors.green)
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
                                  isPast ? Icons.history : Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPast ? 'Past' : 'Upcoming',
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
                      const SizedBox(height: 12),
                      // Description
                      Text(
                        event.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface.withValues(
                            alpha: isPast ? 0.5 : 0.7,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                                color: isPast
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: isPast
                                        ? colorScheme.onSurface
                                            .withValues(alpha: 0.6)
                                        : colorScheme.onPrimaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dateStr,
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: isPast
                                                ? colorScheme.onSurface
                                                : colorScheme
                                                    .onPrimaryContainer,
                                          ),
                                        ),
                                        Text(
                                          timeStr,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: isPast
                                                ? colorScheme.onSurface
                                                    .withValues(alpha: 0.6)
                                                : colorScheme.onPrimaryContainer
                                                    .withValues(alpha: 0.8),
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
                                color: isPast
                                    ? colorScheme.surfaceContainerHighest
                                    : colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: isPast
                                        ? colorScheme.onSurface
                                            .withValues(alpha: 0.6)
                                        : colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      event.location,
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isPast
                                            ? colorScheme.onSurface
                                            : colorScheme.onSecondaryContainer,
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

/// Modern Action Card for Quick Actions Grid
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Modern Option Tile for More Options list
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: enabled 
              ? iconColor.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: enabled ? iconColor : Colors.grey,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: enabled 
              ? theme.colorScheme.onSurface
              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 13,
          color: enabled
              ? theme.colorScheme.onSurface.withValues(alpha: 0.6)
              : theme.colorScheme.onSurface.withValues(alpha: 0.4),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: enabled 
            ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
            : theme.colorScheme.onSurface.withValues(alpha: 0.3),
      ),
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
