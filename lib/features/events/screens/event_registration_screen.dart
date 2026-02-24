import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/registration_model.dart';
import '../../../models/user_model.dart';
import '../providers/registration_provider.dart';

/// Screen for club admins to view and manage event registrations
class EventRegistrationsScreen extends ConsumerWidget {
  final String eventId;

  const EventRegistrationsScreen({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registeredUsersAsync = ref.watch(registeredUsersProvider(eventId));
    final waitlistedUsersAsync = ref.watch(waitlistedUsersProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Registrations'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header section with counts
          _buildHeaderSection(
            context,
            registeredUsersAsync,
            waitlistedUsersAsync,
          ),

          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Registered Students Section
                  _buildSectionTitle(
                    context,
                    'Registered Students',
                    Icons.check_circle,
                  ),
                  const SizedBox(height: 12),
                  registeredUsersAsync.when(
                    data: (users) => _buildRegisteredUsersList(context, users),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => _buildErrorCard(context, error),
                  ),

                  const SizedBox(height: 32),

                  // Waitlisted Students Section
                  _buildSectionTitle(
                    context,
                    'Waitlisted Students',
                    Icons.hourglass_empty,
                  ),
                  const SizedBox(height: 12),
                  waitlistedUsersAsync.when(
                    data: (users) => _buildWaitlistedUsersList(context, users),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, stack) => _buildErrorCard(context, error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build header section with counts
  Widget _buildHeaderSection(
    BuildContext context,
    AsyncValue<List<RegistrationModel>> registeredAsync,
    AsyncValue<List<RegistrationModel>> waitlistedAsync,
  ) {
    final theme = Theme.of(context);
    final registeredCount =
        registeredAsync.valueOrNull?.length.toString() ?? '...';
    final waitlistedCount =
        waitlistedAsync.valueOrNull?.length.toString() ?? '...';

    return Container(
      width: double.infinity,
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
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Registered',
              registeredCount,
              Icons.check_circle,
              theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              context,
              'Waitlisted',
              waitlistedCount,
              Icons.hourglass_empty,
              theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  /// Build stat card for header
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            count,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// Build section title
  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build registered users list
  Widget _buildRegisteredUsersList(
    BuildContext context,
    List<RegistrationModel> registrations,
  ) {
    if (registrations.isEmpty) {
      return _buildEmptyCard(
        context,
        'No registered students yet',
        Icons.person_off,
      );
    }

    return Column(
      children: registrations
          .map((registration) => _UserCard(
                registration: registration,
                isRegistered: true,
              ))
          .toList(),
    );
  }

  /// Build waitlisted users list
  Widget _buildWaitlistedUsersList(
    BuildContext context,
    List<RegistrationModel> registrations,
  ) {
    if (registrations.isEmpty) {
      return _buildEmptyCard(
        context,
        'No waitlisted students',
        Icons.schedule,
      );
    }

    return Column(
      children: registrations
          .map((registration) => _UserCard(
                registration: registration,
                isRegistered: false,
              ))
          .toList(),
    );
  }

  /// Build empty state card
  Widget _buildEmptyCard(BuildContext context, String message, IconData icon) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard(BuildContext context, Object error) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading registrations: ${error.toString()}',
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display user information card
class _UserCard extends ConsumerWidget {
  final RegistrationModel registration;
  final bool isRegistered;

  const _UserCard({
    required this.registration,
    required this.isRegistered,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<UserModel?>(
      future: _fetchUserData(registration.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(
                    'Loading...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.errorContainer,
                child: Icon(
                  Icons.person,
                  color: theme.colorScheme.error,
                ),
              ),
              title: const Text('User not found'),
              subtitle: Text('ID: ${registration.userId}'),
            ),
          );
        }

        final user = snapshot.data!;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  backgroundColor: isRegistered
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.secondaryContainer,
                  radius: 24,
                  child: Text(
                    user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isRegistered
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // User info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      if (registration.registeredAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Registered: ${_formatDate(registration.registeredAt!)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Mark Attendance button (only for registered users)
                if (isRegistered) ...[
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      _markAttendance(context, user.name);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Mark'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Fetch user data from Firestore
  Future<UserModel?> _fetchUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      return null;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Mark attendance for a user
  void _markAttendance(BuildContext context, String userName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance marked for $userName'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    // TODO: Implement actual attendance marking logic
  }
}
