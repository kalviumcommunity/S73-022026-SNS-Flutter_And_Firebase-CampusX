import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';

class ViewProfileScreen extends ConsumerWidget {
  final String userId;

  const ViewProfileScreen({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading profile: $error'),
            ],
          ),
        ),
        data: (user) {
          if (user == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64),
                  SizedBox(height: 16),
                  Text('User not found'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Photo
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  backgroundImage: user.profilePhotoUrl != null
                      ? NetworkImage(user.profilePhotoUrl!)
                      : null,
                  child: user.profilePhotoUrl == null
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                        )
                      : null,
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Role Badge
                Chip(
                  label: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  avatar: const Icon(Icons.badge, size: 16),
                ),
                const SizedBox(height: 24),

                // Bio
                if (user.bio != null && user.bio!.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'About',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(user.bio!),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Contact Information
                Card(
                  child: Column(
                    children: [
                      // Email
                      if (user.showEmail)
                        ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email'),
                          subtitle: Text(user.email),
                        ),

                      // Phone
                      if (user.phone != null && user.phone!.isNotEmpty && user.showPhone)
                        ListTile(
                          leading: const Icon(Icons.phone),
                          title: const Text('Phone'),
                          subtitle: Text(user.phone!),
                        ),

                      // Show message if contact hidden
                      if (!user.showEmail && (user.phone == null || !user.showPhone))
                        const ListTile(
                          leading: Icon(Icons.lock_outline),
                          title: Text('Contact information is private'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Stats
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '${user.joinedClubs.length}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Joined Clubs'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                '${user.adminClubs.length}',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text('Admin Clubs'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
