import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/user_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _showChangePasswordDialog() async {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Current Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Confirm New Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value != _newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              Navigator.pop(context);

              await ref.read(profileOperationsProvider.notifier).changePassword(
                currentPassword: _currentPasswordController.text,
                newPassword: _newPasswordController.text,
              );
            },
            child: const Text('Change Password'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final userId = user?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in')),
      );
    }

    final userAsync = ref.watch(userStreamProvider(userId));

    // Listen for operation results
    ref.listen(profileOperationsProvider, (previous, next) {
      if (next.status == ProfileOperationStatus.success && next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(profileOperationsProvider.notifier).reset();
      } else if (next.status == ProfileOperationStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(profileOperationsProvider.notifier).reset();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
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
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return ListView(
            children: [
              // Account Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Edit Profile'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/profile'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.lock),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Privacy Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Privacy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.email),
                      title: const Text('Show Email'),
                      subtitle: const Text('Others can see your email address'),
                      value: user.showEmail,
                      onChanged: (value) {
                        ref.read(profileOperationsProvider.notifier).updatePrivacySettings(
                          userId: userId,
                          showEmail: value,
                        );
                      },
                    ),
                    SwitchListTile(
                      secondary: const Icon(Icons.phone),
                      title: const Text('Show Phone'),
                      subtitle: const Text('Others can see your phone number'),
                      value: user.showPhone,
                      onChanged: (value) {
                        ref.read(profileOperationsProvider.notifier).updatePrivacySettings(
                          userId: userId,
                          showPhone: value,
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Notifications Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notification Settings'),
                  subtitle: const Text('Manage push notification preferences'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notification-settings'),
                ),
              ),
              const SizedBox(height: 16),

              // About Section
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'About',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('App Version'),
                      trailing: const Text('1.0.0'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.description),
                      title: const Text('Terms & Conditions'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Show terms
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.privacy_tip),
                      title: const Text('Privacy Policy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Show privacy policy
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Logout Section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && mounted) {
                      await ref.read(authProvider.notifier).logout();
                      if (mounted) {
                        context.go('/login');
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }
}
