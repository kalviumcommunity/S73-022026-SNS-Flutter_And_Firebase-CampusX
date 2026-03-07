import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SystemSettingsScreen extends ConsumerWidget {
  const SystemSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'System Settings',
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Platform Configuration',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage system-wide settings and configurations',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 24),

          // General Settings Section
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Configure push notifications'),
                  trailing: Switch(
                    value: true,
                    onChanged: null, // TODO: Implement
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Firestore Rules'),
                  subtitle: const Text('View security rules'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showComingSoonDialog(context, 'Firestore Rules Management');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup),
                  title: const Text('Backup & Restore'),
                  subtitle: const Text('Manage data backups'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showComingSoonDialog(context, 'Backup Management');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Platform Settings
          Text(
            'Platform Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.school),
                  title: const Text('College Information'),
                  subtitle: const Text('Update college details'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showComingSoonDialog(context, 'College Information Management');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.event),
                  title: const Text('Event Settings'),
                  subtitle: const Text('Configure event parameters'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showComingSoonDialog(context, 'Event Settings');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('User Roles'),
                  subtitle: const Text('Manage role permissions'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showComingSoonDialog(context, 'Role Permissions');
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Danger Zone
          Text(
            'Danger Zone',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            color: theme.colorScheme.errorContainer.withOpacity(0.3),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Clear All Data',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Permanently delete all platform data'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDangerDialog(
                      context,
                      'Clear All Data',
                      'This action will permanently delete all data from the platform. This cannot be undone.',
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.refresh,
                    color: theme.colorScheme.error,
                  ),
                  title: Text(
                    'Reset Platform',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  subtitle: const Text('Reset to default configuration'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    _showDangerDialog(
                      context,
                      'Reset Platform',
                      'This will reset all platform settings to their default values.',
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Coming Soon'),
        content: Text('$feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDangerDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('This feature is not implemented yet'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text(
              'Confirm',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
