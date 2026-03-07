import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../models/club_model.dart';
import '../../../core/services/club_service.dart';
import '../../clubs/providers/club_provider.dart';

/// Provider for all clubs (including inactive) for admin management
final allClubsStreamProvider = StreamProvider<List<ClubModel>>((ref) {
  return FirebaseFirestore.instance
      .collection('clubs')
      .snapshots()
      .map((snapshot) {
    final clubs = snapshot.docs
        .map((doc) => ClubModel.fromMap(doc.data(), doc.id))
        .toList();
    
    // Sort clubs by name
    clubs.sort((a, b) => a.name.compareTo(b.name));
    return clubs;
  });
});

class ManageClubsScreen extends ConsumerWidget {
  const ManageClubsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubsAsync = ref.watch(allClubsStreamProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Manage Clubs',
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
      body: clubsAsync.when(
        data: (clubs) {
          if (clubs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 80,
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Clubs Yet',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Clubs will appear here when created',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clubs.length,
            itemBuilder: (context, index) {
              final club = clubs[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: club.isActive
                        ? theme.colorScheme.primaryContainer
                        : theme.colorScheme.errorContainer,
                    child: Icon(
                      Icons.groups,
                      color: club.isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.error,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          club.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (!club.isActive)
                        Chip(
                          label: const Text(
                            'Suspended',
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: theme.colorScheme.errorContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.error,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        club.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${club.memberCount} members',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.admin_panel_settings,
                            size: 16,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${club.adminIds.length} admins',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'manage_admins') {
                        await _showManageAdminsDialog(context, ref, club);
                      } else if (value == 'view_details') {
                        context.push('/clubs/${club.id}');
                      } else if (value == 'toggle_status') {
                        await _toggleClubStatus(context, ref, club);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'manage_admins',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings),
                            SizedBox(width: 8),
                            Text('Manage Admins'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'view_details',
                        child: Row(
                          children: [
                            Icon(Icons.visibility),
                            SizedBox(width: 8),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'toggle_status',
                        child: Row(
                          children: [
                            Icon(
                              club.isActive ? Icons.block : Icons.check_circle,
                              color: club.isActive ? Colors.red : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            Text(club.isActive ? 'Suspend Club' : 'Activate Club'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    context.push('/clubs/${club.id}');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 60,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading clubs',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
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

/// Toggle club active/suspended status
Future<void> _toggleClubStatus(
  BuildContext context,
  WidgetRef ref,
  ClubModel club,
) async {
  final clubService = ref.read(clubServiceProvider);
  final newStatus = !club.isActive;
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(newStatus ? 'Activate Club' : 'Suspend Club'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            newStatus
                ? 'Are you sure you want to activate "${club.name}"?'
                : 'Are you sure you want to suspend "${club.name}"?',
          ),
          if (!newStatus) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(dialogContext).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Theme.of(dialogContext).colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Suspending this club will make it inactive. Members won\'t be able to access club features.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(dialogContext).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: FilledButton.styleFrom(
            backgroundColor: newStatus
                ? Theme.of(dialogContext).colorScheme.primary
                : Theme.of(dialogContext).colorScheme.error,
          ),
          child: Text(newStatus ? 'Activate' : 'Suspend'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await clubService.setClubActiveStatus(club.id, newStatus);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? '${club.name} has been activated'
                  : '${club.name} has been suspended',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

/// Show dialog to manage club admins
Future<void> _showManageAdminsDialog(
  BuildContext context,
  WidgetRef ref,
  ClubModel club,
) async {
  final clubService = ref.read(clubServiceProvider);

  await showDialog(
    context: context,
    builder: (dialogContext) => _ManageAdminsDialog(
      club: club,
      clubService: clubService,
    ),
  );
}

/// Dialog widget for managing club admins
class _ManageAdminsDialog extends StatefulWidget {
  final ClubModel club;
  final ClubService clubService;

  const _ManageAdminsDialog({
    required this.club,
    required this.clubService,
  });

  @override
  State<_ManageAdminsDialog> createState() => _ManageAdminsDialogState();
}

class _ManageAdminsDialogState extends State<_ManageAdminsDialog> {
  List<Map<String, dynamic>>? _members;
  List<Map<String, dynamic>>? _currentAdmins;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final members = await widget.clubService.getClubMembers(widget.club.id);
      
      // Fetch current admin details
      final adminDetails = <Map<String, dynamic>>[];
      for (final adminId in widget.club.adminIds) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(adminId)
            .get();
        if (adminDoc.exists) {
          adminDetails.add({
            'uid': adminId,
            ...adminDoc.data()!,
          });
        }
      }

      if (mounted) {
        setState(() {
          _members = members;
          _currentAdmins = adminDetails;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _addAdmin(Map<String, dynamic> user) async {
    try {
      await widget.clubService.addClubAdmin(widget.club.id, user['uid']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user['name']} added as admin')),
        );
        _loadData(); // Reload data
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _removeAdmin(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Admin'),
        content: Text('Remove ${user['name']} as admin of ${widget.club.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.clubService.removeClubAdmin(widget.club.id, user['uid']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user['name']} removed as admin')),
          );
          _loadData(); // Reload data
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Admins',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.club.name,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            if (_isLoading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current Admins Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Current Admins (${_currentAdmins?.length ?? 0})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_currentAdmins!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'No admins assigned',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      else
                        ..._currentAdmins!.map((admin) => ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  admin['name'][0].toUpperCase(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              title: Text(admin['name']),
                              subtitle: Text(admin['email']),
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => _removeAdmin(admin),
                                color: theme.colorScheme.error,
                              ),
                            )),

                      const Divider(height: 32),

                      // Add Members as Admins Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Club Members',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_members!.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No approved members yet',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        )
                      else
                        ..._members!.map((member) {
                          final isAdmin = widget.club.adminIds.contains(member['uid']);
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isAdmin
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceVariant,
                              child: Text(
                                member['name'][0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isAdmin
                                      ? theme.colorScheme.primary
                                      : null,
                                ),
                              ),
                            ),
                            title: Text(member['name']),
                            subtitle: Text(member['email']),
                            trailing: isAdmin
                                ? Chip(
                                    label: const Text('Admin'),
                                    backgroundColor:
                                        theme.colorScheme.primaryContainer,
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _addAdmin(member),
                                    color: theme.colorScheme.primary,
                                  ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
