import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/user_service.dart';
import '../../../models/notification_preferences.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen for managing notification preferences
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  final UserService _userService = UserService();
  
  bool _isLoading = false;
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final enabled = await _notificationService.areNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _requestPermissions() async {
    final granted = await _notificationService.requestPermissions();
    if (mounted) {
      setState(() {
        _notificationsEnabled = granted;
      });
      
      if (granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification permissions denied'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updatePreferences(NotificationPreferences preferences) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _userService.updateNotificationPreferences(
        userId: currentUser.uid,
        preferences: preferences,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notification Settings'),
        ),
        body: const Center(
          child: Text('Please log in to manage notification settings'),
        ),
      );
    }

    final preferences = currentUser.notificationPreferences;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_active,
                              size: 32,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Push Notifications',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _notificationsEnabled
                                        ? 'Enabled'
                                        : 'Disabled',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: _notificationsEnabled
                                          ? Colors.green
                                          : Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_notificationsEnabled) ...[
                          const SizedBox(height: 16),
                          const Text(
                            'Enable notifications to stay updated with announcements, events, and important updates from your clubs.',
                          ),
                          const SizedBox(height: 12),
                          FilledButton.icon(
                            onPressed: _requestPermissions,
                            icon: const Icon(Icons.notifications),
                            label: const Text('Enable Notifications'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Notification Types
                Text(
                  'Notification Types',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose which types of notifications you want to receive',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 16),

                // Announcements
                Card(
                  child: SwitchListTile(
                    value: preferences.announcements,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            _updatePreferences(
                              preferences.copyWith(announcements: value),
                            );
                          }
                        : null,
                    title: const Text('Announcements'),
                    subtitle: const Text('New club announcements'),
                    secondary: const Icon(Icons.campaign),
                  ),
                ),
                const SizedBox(height: 8),

                // Event Registrations
                Card(
                  child: SwitchListTile(
                    value: preferences.eventRegistrations,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            _updatePreferences(
                              preferences.copyWith(eventRegistrations: value),
                            );
                          }
                        : null,
                    title: const Text('Event Registrations'),
                    subtitle: const Text('Confirmation and event updates'),
                    secondary: const Icon(Icons.event),
                  ),
                ),
                const SizedBox(height: 8),

                // Team Membership
                Card(
                  child: SwitchListTile(
                    value: preferences.teamMembership,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            _updatePreferences(
                              preferences.copyWith(teamMembership: value),
                            );
                          }
                        : null,
                    title: const Text('Team Membership'),
                    subtitle: const Text('Team invites and approvals'),
                    secondary: const Icon(Icons.groups),
                  ),
                ),
                const SizedBox(height: 8),

                // Interviews
                Card(
                  child: SwitchListTile(
                    value: preferences.interviews,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            _updatePreferences(
                              preferences.copyWith(interviews: value),
                            );
                          }
                        : null,
                    title: const Text('Interviews'),
                    subtitle: const Text('Interview schedules and updates'),
                    secondary: const Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 8),

                // Event Reminders
                Card(
                  child: SwitchListTile(
                    value: preferences.eventReminders,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            _updatePreferences(
                              preferences.copyWith(eventReminders: value),
                            );
                          }
                        : null,
                    title: const Text('Event Reminders'),
                    subtitle: const Text('Reminders 1 hour before events'),
                    secondary: const Icon(Icons.alarm),
                  ),
                ),
                const SizedBox(height: 8),

                // General
                Card(
                  child: SwitchListTile(
                    value: preferences.general,
                    onChanged: _notificationsEnabled
                        ? (value) {
                            _updatePreferences(
                              preferences.copyWith(general: value),
                            );
                          }
                        : null,
                    title: const Text('General'),
                    subtitle: const Text('System updates and other notifications'),
                    secondary: const Icon(Icons.info),
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _notificationsEnabled &&
                                !preferences.allEnabled
                            ? () {
                                _updatePreferences(
                                  const NotificationPreferences(
                                    announcements: true,
                                    eventRegistrations: true,
                                    teamMembership: true,
                                    interviews: true,
                                    eventReminders: true,
                                    general: true,
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Enable All'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _notificationsEnabled &&
                                !preferences.allDisabled
                            ? () {
                                _updatePreferences(
                                  const NotificationPreferences(
                                    announcements: false,
                                    eventRegistrations: false,
                                    teamMembership: false,
                                    interviews: false,
                                    eventReminders: false,
                                    general: false,
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Disable All'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Info Card
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'You can change these settings anytime. Disabling a notification type will stop receiving those notifications.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
