import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/providers/auth_provider.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('College Admin Dashboard'),
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
            children: [
              const SizedBox(height: 24),
              Icon(
                Icons.security,
                size: 100,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, ${user?.name ?? 'Admin'}!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'College Admin Dashboard',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Role: ${user?.role ?? 'N/A'}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.dashboard),
                        title: const Text('Analytics'),
                        subtitle: const Text('View platform statistics'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.push('/admin/analytics');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.groups),
                        title: const Text('Manage Clubs'),
                        subtitle: const Text('Oversee all college clubs'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.push('/admin/manage-clubs');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.admin_panel_settings),
                        title: const Text('Role Requests'),
                        subtitle: const Text('Review role upgrade requests'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.push('/role-requests');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.people),
                        title: const Text('User Management'),
                        subtitle: const Text('Manage users and permissions'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.push('/admin/users');
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.settings),
                        title: const Text('System Settings'),
                        subtitle: const Text('Configure platform settings'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          context.push('/admin/settings');
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
