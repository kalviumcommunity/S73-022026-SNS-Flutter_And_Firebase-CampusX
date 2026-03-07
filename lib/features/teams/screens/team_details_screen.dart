import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/team_service.dart';
import '../../../models/team_model.dart';
import '../../auth/providers/auth_provider.dart';
import './manage_teams_screen.dart';

/// Provider for team members
final teamMembersProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, teamId) {
  final teamService = ref.watch(teamServiceProvider);
  return teamService.getTeamMembers(teamId);
});

/// Provider for team details
final teamDetailsProvider = FutureProvider.family<TeamModel?, String>((ref, teamId) async {
  final doc = await FirebaseFirestore.instance.collection('teams').doc(teamId).get();
  if (!doc.exists) return null;
  return TeamModel.fromMap(doc.data()!, doc.id);
});

class TeamDetailsScreen extends ConsumerWidget {
  final String teamId;

  const TeamDetailsScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailsProvider(teamId));
    final membersAsync = ref.watch(teamMembersProvider(teamId));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Team Details',
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
      body: teamAsync.when(
        data: (team) {
          if (team == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                  const SizedBox(height: 16),
                  const Text('Team not found'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Team Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.groups, size: 40, color: theme.colorScheme.primary),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        team.name,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 20, color: Colors.white.withOpacity(0.9)),
                          const SizedBox(width: 4),
                          Text(
                            '${team.memberCount} members',
                            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withOpacity(0.9)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Team Description
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(team.description, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),

                const Divider(),

                // Members Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Team Members',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                membersAsync.when(
                  data: (members) {
                    if (members.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.people_outline, size: 60, color: theme.colorScheme.primary.withOpacity(0.5)),
                              const SizedBox(height: 16),
                              Text('No members yet', style: theme.textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Members will appear here once they join', style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        final member = members[index];
                        final isHead = member['role'] == 'team_head';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor: isHead 
                                  ? Colors.amber.withOpacity(0.3)
                                  : theme.colorScheme.primaryContainer,
                              child: Text(
                                member['name'][0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isHead ? Colors.amber[800] : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    member['name'],
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (isHead)
                                  Chip(
                                    label: const Text('Head', style: TextStyle(fontSize: 12)),
                                    backgroundColor: Colors.amber,
                                    padding: EdgeInsets.zero,
                                    avatar: const Icon(Icons.star, size: 16, color: Colors.white),
                                  ),
                              ],
                            ),
                            subtitle: Text(member['email']),
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) async {
                                if (value == 'make_head') {
                                  await _makeTeamHead(context, ref, team, member);
                                } else if (value == 'remove_head') {
                                  await _removeTeamHead(context, ref, team, member);
                                } else if (value == 'remove') {
                                  await _removeMember(context, ref, member);
                                }
                              },
                              itemBuilder: (context) {
                                if (isHead) {
                                  return [
                                    const PopupMenuItem(
                                      value: 'remove_head',
                                      child: Row(
                                        children: [
                                          Icon(Icons.remove_circle_outline, color: Colors.orange),
                                          SizedBox(width: 8),
                                          Text('Remove as Head'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Remove from Team'),
                                        ],
                                      ),
                                    ),
                                  ];
                                } else {
                                  return [
                                    if (team.headId == null)
                                      const PopupMenuItem(
                                        value: 'make_head',
                                        child: Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber),
                                            SizedBox(width: 8),
                                            Text('Make Team Head'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuItem(
                                      value: 'remove',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Remove from Team'),
                                        ],
                                      ),
                                    ),
                                  ];
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
                          const SizedBox(height: 16),
                          Text('Error loading members', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(error.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: theme.colorScheme.error),
              const SizedBox(height: 16),
              Text('Error loading team', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(error.toString(), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makeTeamHead(BuildContext context, WidgetRef ref, TeamModel team, Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Make Team Head'),
        content: Text('Make ${member['name']} the head of ${team.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamService = ref.read(teamServiceProvider);
        final user = ref.read(currentUserProvider);
        
        await teamService.addTeamHead(
          teamId: team.id,
          userId: member['userId'],
          promoterId: user!.uid,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member['name']} is now the team head'),
              backgroundColor: Colors.green,
            ),
          );
          // Refresh the team data
          ref.invalidate(teamDetailsProvider(team.id));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _removeTeamHead(BuildContext context, WidgetRef ref, TeamModel team, Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Team Head'),
        content: Text('Remove ${member['name']} as team head? They will remain a team member.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamService = ref.read(teamServiceProvider);
        await teamService.removeTeamHead(
          teamId: team.id,
          membershipId: member['membership'].id,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member['name']} is no longer the team head'),
              backgroundColor: Colors.orange,
            ),
          );
          // Refresh the team data
          ref.invalidate(teamDetailsProvider(team.id));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _removeMember(BuildContext context, WidgetRef ref, Map<String, dynamic> member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Remove ${member['name']} from the team?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final teamService = ref.read(teamServiceProvider);
        await teamService.removeTeamMember(member['membership'].id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${member['name']} removed from team'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
