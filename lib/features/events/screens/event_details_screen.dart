import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../models/event_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/event_provider.dart';
import '../providers/registration_provider.dart';

/// Screen displaying detailed information about a single event
class EventDetailScreen extends ConsumerWidget {
  final String eventId;

  const EventDetailScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventByIdProvider(eventId));
    final authState = ref.watch(authProvider);
    final currentUser = authState.user;
    final operationState = ref.watch(eventOperationsProvider);
    final registrationOpState = ref.watch(registrationOperationsProvider);

    // Watch registration data for current user
    final userRegistrationAsync = currentUser != null
        ? ref.watch(userRegistrationProvider((eventId, currentUser.uid)))
        : null;
    
    final registrationCountAsync = ref.watch(registrationCountProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Event Details',
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
      body: eventAsync.when(
        data: (event) {
          if (event == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Event not found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This event may have been deleted',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          // Check if current user is the creator
          final isCreator = currentUser?.uid == event.createdBy;
          final isClubAdmin = currentUser?.role == 'club_admin';
          final isStudent = currentUser?.role == 'student';
          final isUpcoming = event.date.isAfter(DateTime.now());

          return SingleChildScrollView(
            child: Column(
              children: [
                // Event Details Content with registration info
                registrationCountAsync.when(
                  data: (registeredCount) => _EventDetailsContent(
                    event: event,
                    registeredCount: registeredCount,
                  ),
                  loading: () => _EventDetailsContent(event: event),
                  error: (_, __) => _EventDetailsContent(event: event),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Show Register/Cancel button for students (only for upcoming events)
                      if (isStudent && currentUser != null && isUpcoming) ...[
                        userRegistrationAsync?.when(
                          data: (registration) {
                            return registrationCountAsync.when(
                              data: (registeredCount) {
                                return _buildRegistrationButton(
                                  context,
                                  ref,
                                  event,
                                  currentUser.uid,
                                  registration,
                                  registeredCount,
                                  registrationOpState.isLoading,
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                          loading: () => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ) ?? const SizedBox.shrink(),
                      ],

                      // Show message for past events (students only)
                      if (isStudent && !isUpcoming) ...[
                        Card(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'This event has already ended. Registration is no longer available.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Show Edit and Delete buttons for creator club_admin
                      if (isClubAdmin && isCreator) ...[
                        FilledButton.icon(
                          onPressed: () {
                            context.push('/event-qr/${event.id}');
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text('Event QR Code'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            context.push('/attendance-list/${event.id}');
                          },
                          icon: const Icon(Icons.people),
                          label: const Text('View Attendance'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: operationState.isLoading
                              ? null
                              : () => _navigateToEditEvent(context, event),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Event'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: operationState.isLoading
                              ? null
                              : () => _showDeleteConfirmation(
                                    context,
                                    ref,
                                    event,
                                  ),
                          icon: const Icon(Icons.delete),
                          label: Text(
                            operationState.isLoading
                                ? 'Deleting...'
                                : 'Delete Event',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).colorScheme.error,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],

                      // Show error message
                      if (registrationOpState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Card(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      registrationOpState.error!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      if (operationState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Card(
                            color: Theme.of(context)
                                .colorScheme
                                .errorContainer,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      operationState.error!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onErrorContainer,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading event',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref.invalidate(eventByIdProvider(eventId));
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build registration button based on status
  Widget _buildRegistrationButton(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    String userId,
    dynamic registration,
    int registeredCount,
    bool isLoading,
  ) {
    // User is not registered
    if (registration == null) {
      final hasCapacity = registeredCount < event.capacity;
      final buttonText = hasCapacity ? 'Register' : 'Join Waitlist';
      final icon = hasCapacity ? Icons.how_to_reg : Icons.playlist_add;

      return FilledButton.icon(
        onPressed: isLoading
            ? null
            : () => _handleRegister(context, ref, event, userId),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(isLoading ? 'Processing...' : buttonText),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: hasCapacity
              ? null
              : Theme.of(context).colorScheme.secondary,
        ),
      );
    }

    // User is registered
    if (registration.status == 'registered') {
      return OutlinedButton.icon(
        onPressed: isLoading
            ? null
            : () => _handleCancel(context, ref, event, userId, 'registration'),
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.cancel),
        label: Text(isLoading ? 'Processing...' : 'Cancel Registration'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }

    // User is waitlisted
    return OutlinedButton.icon(
      onPressed: isLoading
          ? null
          : () => _handleCancel(context, ref, event, userId, 'waitlist'),
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.remove_circle_outline),
      label: Text(isLoading ? 'Processing...' : 'Cancel Waitlist'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Theme.of(context).colorScheme.secondary,
      ),
    );
  }

  /// Handle student registration
  Future<void> _handleRegister(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    String userId,
  ) async {
    final success = await ref
        .read(registrationOperationsProvider.notifier)
        .registerForEvent(event.id, event.clubId, userId);

    if (context.mounted && success) {
      final message =
          ref.read(registrationOperationsProvider).successMessage ?? 'Success';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } else if (context.mounted) {
      final error =
          ref.read(registrationOperationsProvider).error ?? 'Failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  /// Handle registration cancellation
  Future<void> _handleCancel(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
    String userId,
    String type,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel ${type == 'registration' ? 'Registration' : 'Waitlist'}'),
        content: Text(
          'Are you sure you want to cancel your ${type == 'registration' ? 'registration' : 'waitlist position'} for "${event.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(registrationOperationsProvider.notifier)
          .cancelRegistration(event.id, userId);

      if (context.mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              type == 'registration'
                  ? 'Registration cancelled successfully'
                  : 'Removed from waitlist',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      } else if (context.mounted) {
        final error =
            ref.read(registrationOperationsProvider).error ?? 'Failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Navigate to edit event screen
  void _navigateToEditEvent(BuildContext context, EventModel event) {
    // TODO: Implement edit event screen
    context.push('/edit-event', extra: event);
  }

  /// Show delete confirmation dialog
  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text(
          'Are you sure you want to delete "${event.title}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.pop();
              _handleDelete(context, ref, event);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Handle event deletion
  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    EventModel event,
  ) async {
    final success = await ref
        .read(eventOperationsProvider.notifier)
        .deleteEvent(event.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Event deleted successfully'),
          ),
        );
        context.pop();
      }
    }
  }
}

/// Widget displaying the main event details content
class _EventDetailsContent extends StatelessWidget {
  final EventModel event;
  final int? registeredCount;

  const _EventDetailsContent({
    required this.event,
    this.registeredCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    // Check if event is upcoming or past
    final isUpcoming = event.date.isAfter(DateTime.now());

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isUpcoming
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isUpcoming ? 'UPCOMING' : 'PAST EVENT',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isUpcoming
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              event.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // Date and Time Card
            _InfoCard(
              icon: Icons.calendar_today,
              title: 'Date & Time',
              content: '${dateFormat.format(event.date)}\n${timeFormat.format(event.date)}',
            ),
            const SizedBox(height: 12),

            // Location Card
            _InfoCard(
              icon: Icons.location_on,
              title: 'Location',
              content: event.location,
            ),
            const SizedBox(height: 12),

            // Capacity Card
            _InfoCard(
              icon: Icons.people,
              title: 'Capacity',
              content: registeredCount != null
                  ? '$registeredCount / ${event.capacity} seats filled'
                  : '${event.capacity} seats',
            ),
            const SizedBox(height: 24),

            // Description Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About This Event',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event.description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying info cards with icon, title, and content
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
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
